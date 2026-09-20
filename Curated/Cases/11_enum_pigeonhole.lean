import Curated.Harness

inductive Color where
  | red
  | green
  | ultraviolet

example (a b c d : Color) :
    a = b ∨ a = c ∨ a = d ∨ b = c ∨ b = d ∨ c = d := by
  benchmark_tactic
