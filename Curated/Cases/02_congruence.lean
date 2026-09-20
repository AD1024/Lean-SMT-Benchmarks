import Curated.Harness

example (f : Int → Int) (a b : Int) (h : a = b) : f a = f b := by
  benchmark_tactic
