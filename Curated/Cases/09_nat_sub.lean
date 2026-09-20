import Curated.Harness

example (a b : Nat) (h : a ≤ b) : a - b = 0 := by
  benchmark_tactic
