import Curated.Harness

example {α β : Type} (p : α → β → Prop)
    (h : ∀ x, ∃ y, p x y) : ∃ f : α → β, ∀ x, p x (f x) := by
  benchmark_tactic
