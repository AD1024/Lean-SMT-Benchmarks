import Curated.Harness

example (f g : Int → Int) (h : ∀ x, f x = g x) : f = g := by
  benchmark_tactic
