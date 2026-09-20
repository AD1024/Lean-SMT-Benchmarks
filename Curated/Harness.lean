import Auto

/-!
# lean-auto lane

Binds `benchmark_tactic` to lean-auto with an SMT solver behind it. lean-auto
preprocesses, monomorphizes, and translates the goal, then emits SMT-LIB and
queries the solver.

`auto.smt.trust` closes the goal on `unsat` without reconstructing a proof, so
this lane is trusted in the same sense as Crush's trusted lane and is the row
to compare against it. It is not comparable to a lane that returns a
kernel-checked term; set `auto.smt.rconsProof` if that is what you want to
measure.

The options are set around the tactic call rather than with file-level
`set_option`s, because a `set_option` applies only to the file it appears in
and would silently not reach a case file that imports this module -- leaving
lean-auto with SMT disabled and reporting an ordinary search failure.

The solver is spawned by name, so it comes from `PATH` rather than from a Lake
dependency: `cvc5` must be on it.
-/

open Lean Elab Tactic Meta Auto

private def runBenchmarkAuto (premises : TSyntaxArray `term) : TacticM Unit :=
    withMainContext do
  -- `*` contributes every local hypothesis, matching what the other lanes pass.
  let mut hints : Array (TSyntax ``Auto.hintelem) := #[← `(Auto.hintelem| *)]
  for premise in premises do
    hints := hints.push (← `(Auto.hintelem| $premise:term))
  let tactic ← `(tactic| auto [$hints,*])
  let start ← IO.monoMsNow
  try
    -- `Options.set` takes any `KVMap.Value`. lean-auto encodes `SolverName` as
    -- its own string name, so the string below is exactly the value
    -- `set_option auto.smt.solver.name cvc5` would store.
    withOptions (fun opts => opts
        |>.setBool `auto.smt true
        |>.set `auto.smt.solver.name "cvc5"
        -- Five seconds, matching every other lane's solver budget.
        |>.set `auto.smt.timeout (5 : Nat)
        |>.setBool `auto.smt.trust true
        -- Duper is not a dependency of this branch; leaving the native path on
        -- would only produce a confusing failure if SMT declined the goal.
        |>.setBool `auto.native false) do
      evalTactic tactic
    logInfo m!"BENCHMARK_MS={(← IO.monoMsNow) - start}"
  catch e =>
    logInfo m!"BENCHMARK_MS={(← IO.monoMsNow) - start}"
    throw e

syntax "benchmark_tactic" : tactic
syntax "benchmark_tactic" "[" term,* "]" : tactic

elab_rules : tactic
  | `(tactic| benchmark_tactic) => runBenchmarkAuto #[]
  | `(tactic| benchmark_tactic [$premises,*]) => runBenchmarkAuto premises
