import Curated.Harness

example (x : Int) (h : 0 ≤ x)
    (_noise : ∀ ys : List Nat, ys ≠ [] → ys.tail.length < ys.length) :
    x ≤ x + 1 := by
  benchmark_tactic
