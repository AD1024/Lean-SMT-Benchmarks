import Duper

/-!
# Duper lane

Binds `benchmark_tactic` to Duper directly, with every local hypothesis and any
premises the case names. No preprocessing stands between the goal and Duper.
-/

open Lean Elab Tactic

private def runBenchmarkDuper (premises : TSyntaxArray `term) : TacticM Unit := do
  let tactic ← `(tactic| duper [*, $premises,*])
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
  | `(tactic| benchmark_tactic) => runBenchmarkDuper #[]
  | `(tactic| benchmark_tactic [$premises,*]) => runBenchmarkDuper premises
