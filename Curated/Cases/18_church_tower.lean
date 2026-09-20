import Curated.Harness

example {α : Type}
    (add : ((α → α) → (α → α)) → ((α → α) → (α → α)) →
      ((α → α) → (α → α)))
    (hadd : ∀ x y f n, add x y f n = (x f) ((y f) n))
    (mul : ((α → α) → (α → α)) → ((α → α) → (α → α)) →
      ((α → α) → (α → α)))
    (hmul : ∀ x y f, mul x y f = x (y f))
    (two : (α → α) → (α → α))
    (htwo : ∀ f x, two f x = f (f x))
    (three : (α → α) → (α → α))
    (hthree : ∀ f x, three f x = f (f (f x))) :
    mul three (add two (add three three)) =
      mul three (mul two (add two two)) := by
  benchmark_tactic [hadd, hmul, htwo, hthree]
