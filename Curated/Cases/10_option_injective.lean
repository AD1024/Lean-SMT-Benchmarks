import Curated.Harness

example {α : Type} (x y : α)
    (h : Option.some x = Option.some y) : x = y := by
  benchmark_tactic
