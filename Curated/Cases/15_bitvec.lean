import Curated.Harness

example (a b : BitVec 10) : a + b = b + a := by
  benchmark_tactic
