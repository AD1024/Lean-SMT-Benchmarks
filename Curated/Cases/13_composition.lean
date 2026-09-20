import Curated.Harness

example {α β γ : Type}
    (p : (α → γ) → Prop) (f : α → β) (g : β → γ) (h : β → β) :
    p ((g ∘ h) ∘ f) = p (fun x => g (h (f x))) := by
  benchmark_tactic [Function.comp_def]
