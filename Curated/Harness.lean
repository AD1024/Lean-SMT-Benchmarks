import Smt

/-!
# lean-smt lane

Binds `benchmark_tactic` to lean-smt, which translates the goal, calls cvc5,
and replays the Alethe certificate in Lean.

lean-smt reports an Alethe rule it cannot replay by leaving that step as an
open goal rather than by failing, so a lane that only checked the tactic's exit
status would count those as solved. This harness checks the goal list itself
and emits its own machine record. The record uses the same field layout and
reconstruction vocabulary as Crush's `crush.profile.machine` output, so a
driver can normalize both into one report.

The solver configuration is fixed here rather than taken from the environment:
a five-second timeout with monomorphization, which is what every published
measurement of this lane used. Changing it is a change to this branch.
-/

open Lean Elab Tactic Meta

private def smtBenchSanitize (value : String) : String :=
  value.replace "\t" " " |>.replace "\n" " " |>.replace "\r" " "

private def smtBenchRecord (decl : String) (goalHash : UInt64)
    (outcome replay detail : String) (nanos : Nat) : String :=
  s!"SMT_PROFILE\t1\t{smtBenchSanitize decl}\t{goalHash}\t{outcome}\t\
{replay}\t{smtBenchSanitize detail}\t{nanos}\t\t"

private def smtBenchContains (text needle : String) : Bool :=
  (text.splitOn needle).length > 1

/-- Classify a lean-smt diagnostic with the shared reconstruction vocabulary. -/
private def smtBenchOutcome (message : String) : String × String :=
  let text := message.toLower
  if smtBenchContains text "either it is false" ||
      smtBenchContains text "could not produce a counter-example" then
    ("sat", "-")
  else if smtBenchContains text "try providing more hints" ||
      smtBenchContains text "solver returned unknown" then
    ("unknown", "-")
  else if smtBenchContains text "failed to reconstruct proof for unsat result" then
    ("reconstruction-failed", "no-certificate")
  else if smtBenchContains text "failed to reconstruct sort" ||
      smtBenchContains text "failed to reconstruct term" ||
      smtBenchContains text "expected a sort, but got" then
    ("reconstruction-failed", "term-gap")
  -- lean-smt's own translators report the first two. The rest are cvc5
  -- rejecting a query lean-smt had already built, which is still an encoding
  -- limit and not a replay one: no proof existed to replay. Observed on this
  -- workload as a higher-order arrow reaching the parser, a variable-width
  -- bitvector, and an empty datatype declaration.
  else if smtBenchContains text "no translator matched" ||
      smtBenchContains text "cannot translate" ||
      smtBenchContains text "not declared as a type" ||
      smtBenchContains text "has variable width" ||
      smtBenchContains text "invalid datatype declaration" then
    ("translation-failed", "-")
  else if smtBenchContains text "unexpected check-sat result" then
    ("reconstruction-failed", "certificate-error")
  else if smtBenchContains text "maximum number of heartbeats" ||
      smtBenchContains text "deterministic) timeout" ||
      smtBenchContains text "timed out" then
    ("timeout", "-")
  -- Any other error raised through the cvc5 API. Kept distinct so it is not
  -- silently attributed to certificate replay.
  else if smtBenchContains text "cvc5.error" then
    ("solver-error", "-")
  else
    ("reconstruction-failed", "replay-exception")

private def runBenchmarkSmt (premises : TSyntaxArray `term) : TacticM Unit :=
    withMainContext do
  -- `[*]` already contributes every local hypothesis. Naming one again as a
  -- hint makes Auto's monomorphization reject the whole query with "does not
  -- accept duplicated input terms", so drop hints that only name a
  -- hypothesis. Hints naming global lemmas are kept.
  let lctx ← getLCtx
  let hints : Array (TSyntax `Smt.Tactic.smtHintElem) ←
    premises.filterMapM fun premise => do
      if premise.raw.isIdent &&
          (lctx.findFromUserName? premise.raw.getId).isSome then
        return none
      return some (← `(Smt.Tactic.smtHintElem| $premise:term))
  let decl := toString ((← Term.getDeclName?).getD `anonymous)
  let goalText := (toString (← ppExpr (← (← getMainGoal).getType)))
    |>.replace "\t" " "
    |>.replace "\n" " "
  let goalHash := hash goalText
  let start ← IO.monoNanosNow
  -- CoreM's ordinary `try` rethrows heartbeat exhaustion without running the
  -- handler, which would drop this VC's record entirely.
  let failure? ← tryCatchRuntimeEx
    (do
      evalTactic (← `(tactic| smt +mono (timeout := 5) [*, $hints,*]))
      pure none)
    (fun ex => pure (some ex))
  let nanos := (← IO.monoNanosNow) - start
  logInfo m!"BENCHMARK_MS={nanos / 1000000}"
  match failure? with
  | none =>
    let remaining ← getUnsolvedGoals
    if remaining.isEmpty then
      IO.println (smtBenchRecord decl goalHash "alethe-reconstructed" "-" "-" nanos)
    else
      IO.println (smtBenchRecord decl goalHash "reconstruction-failed" "rule-gap"
        s!"{remaining.length} replayed step(s) left as open goals" nanos)
      throwError "lean-smt did not close the goal: \
{remaining.length} open goal(s) remain after proof replay"
  | some ex =>
    let message ← ex.toMessageData.toString
    let (outcome, replay) := smtBenchOutcome message
    IO.println (smtBenchRecord decl goalHash outcome replay message nanos)
    throw ex

syntax "benchmark_tactic" : tactic
syntax "benchmark_tactic" "[" term,* "]" : tactic

elab_rules : tactic
  | `(tactic| benchmark_tactic) => runBenchmarkSmt #[]
  | `(tactic| benchmark_tactic [$premises,*]) => runBenchmarkSmt premises
