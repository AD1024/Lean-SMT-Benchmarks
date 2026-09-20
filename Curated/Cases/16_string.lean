import Curated.Harness

example (a b c : String) : (a ++ b) ++ c = a ++ (b ++ c) := by
  benchmark_tactic
