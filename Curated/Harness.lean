import Crush

/-!
# Crush lane

Binds `benchmark_tactic` to Crush. Every setting comes from `crush.*` options,
so one branch serves each of Crush's modes: the trusted lane is
`-Dcrush.trust=trust`, and the kernel-checked lanes are
`-Dcrush.trust=reconstruct` with `-Dcrush.reconstruct=` one of `alethe`,
`core`, or `auto`. Nothing is hard-coded here that a driver might want to vary,
and nothing a driver sets is silently overridden.
-/

open Lean Elab Tactic

private def runBenchmarkCrush (premises : TSyntaxArray `term) : TacticM Unit :=
    withMainContext do
  let terms ← premises.mapM fun premise => do
    let proof ← Term.elabTerm premise none
    Term.synthesizeSyntheticMVarsNoPostponing
    let proof ← instantiateMVars proof
    let descr := premise.reprint.getD "benchmark hint"
    pure (proof, descr)
  let cfg := Crush.Config.ofOptions (← getOptions)
  let start ← IO.monoMsNow
  try
    Crush.runCrush (← getMainGoal) cfg {
      terms
      -- Matches the other lanes, which all see the whole local context.
      allHyps := true
      -- The case names its own premises; selection would make the lanes differ
      -- in what they were given rather than in what they could do with it.
      allowPremiseSelection := false
    }
    logInfo m!"BENCHMARK_MS={(← IO.monoMsNow) - start}"
  catch e =>
    logInfo m!"BENCHMARK_MS={(← IO.monoMsNow) - start}"
    throw e

syntax "benchmark_tactic" : tactic
syntax "benchmark_tactic" "[" term,* "]" : tactic

elab_rules : tactic
  | `(tactic| benchmark_tactic) => runBenchmarkCrush #[]
  | `(tactic| benchmark_tactic [$premises,*]) => runBenchmarkCrush premises
