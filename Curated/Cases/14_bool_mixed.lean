import Curated.Harness

example {a b c d : Bool}
    (h : if (if (2 < 3) then a else b) then c else d) :
    (a → c) ∧ (¬a → d) := by
  benchmark_tactic
