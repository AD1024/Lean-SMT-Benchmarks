import Curated.Harness

example {α β : Type} {xs : List α} {ys : List β} {r : Prop}
    (p : ∀ γ : Type, List γ → Prop)
    (q : ∀ γ : Type, List γ → Prop)
    (combine : ∀ γ δ as bs, p γ as → q δ bs → r)
    (hp : p α xs) (hq : q β ys) : r := by
  benchmark_tactic [combine, hp, hq]
