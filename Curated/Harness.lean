import Lean

/-!
# Case harness

Every case closes its goal with `benchmark_tactic`. That one tactic is the
seam: a driver measuring a particular backend regenerates the case with its own
import at the top and binds `benchmark_tactic` to call that backend directly.
The goal text is never rewritten, so every backend sees exactly the same
obligation with exactly the same premises.

Bound here to `grind`, which needs nothing beyond Lean itself. That makes the
suite runnable straight from a checkout, and makes the default lane one of the
baselines rather than a placeholder.
-/

open Lean Elab Tactic

private def runBenchmarkGrind (premises : TSyntaxArray `term) : TacticM Unit := do
  let params : TSyntaxArray `Lean.Parser.Tactic.grindParam ←
    premises.mapM fun premise => do
      let premise : TSyntax `term := ⟨premise⟩
      `(Lean.Parser.Tactic.grindParam| $(premise):term)
  let tactic ← `(tactic| grind [$params,*])
  let start ← IO.monoMsNow
  try
    evalTactic tactic
    logInfo m!"BENCHMARK_MS={(← IO.monoMsNow) - start}"
  catch e =>
    logInfo m!"BENCHMARK_MS={(← IO.monoMsNow) - start}"
    throw e

syntax "benchmark_tactic" : tactic
syntax "benchmark_tactic" "[" term,* "]" : tactic

elab_rules : tactic
  | `(tactic| benchmark_tactic) => runBenchmarkGrind #[]
  | `(tactic| benchmark_tactic [$premises,*]) => runBenchmarkGrind premises
