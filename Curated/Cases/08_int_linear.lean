import Curated.Harness

example (x y z : Int)
    (hxy : x ≤ y) (hyz : y < z) : x + 1 ≤ z := by
  benchmark_tactic
