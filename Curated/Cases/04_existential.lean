import Curated.Harness

example (p q : Int → Prop) (x : Int)
    (step : ∀ y, p y → ∃ z, q z) (hp : p x) : ∃ z, q z := by
  benchmark_tactic
