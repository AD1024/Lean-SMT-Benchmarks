import Curated.Harness

example {α : Type} (xs ys zs : List α) :
    (xs ++ ys) ++ zs = xs ++ (ys ++ zs) := by
  benchmark_tactic [List.append_assoc]
