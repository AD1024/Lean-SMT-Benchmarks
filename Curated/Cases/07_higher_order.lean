import Curated.Harness

example (applyAtOne : (Int → Int) → Int)
    (h : ∀ f, applyAtOne f = f 1) :
    applyAtOne (fun x => x + 1) = 2 := by
  benchmark_tactic
