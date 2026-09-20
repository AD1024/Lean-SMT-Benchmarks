import Curated.Harness

example (p q : Int → Prop) (x : Int)
    (hpq : ∀ y, p y → q y) (hp : p x) : q x := by
  benchmark_tactic
