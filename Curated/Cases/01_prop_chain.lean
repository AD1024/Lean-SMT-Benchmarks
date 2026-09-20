import Curated.Harness

example (p q r : Prop) (hpq : p → q) (hqr : q → r) (hp : p) : r := by
  benchmark_tactic
