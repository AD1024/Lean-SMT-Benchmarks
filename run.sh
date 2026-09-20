#!/usr/bin/env bash
set -euo pipefail

# Runs the default lane -- `grind`, which the harness binds `benchmark_tactic`
# to -- over every case. Other backends are measured by a driver that
# regenerates each case against its own import; see README.md.

cd "$(dirname "$0")"

repeats="${1:-3}"
results="results.tsv"
logs=".logs"

lake build Curated >/dev/null

mkdir -p "$logs"
printf 'case\trun\tstatus\ttactic_ms\n' > "$results"

for case_file in Curated/Cases/*.lean; do
  case_name="$(basename "$case_file" .lean)"
  for ((run = 1; run <= repeats; run++)); do
    log="$logs/${case_name}-${run}.log"
    if lake env lean "$case_file" >"$log" 2>&1; then
      status=pass
    else
      status=fail
    fi
    tactic_ms="$(sed -n 's/.*BENCHMARK_MS=\([0-9][0-9]*\).*/\1/p' "$log" | tail -n 1)"
    tactic_ms="${tactic_ms:-0}"
    printf '%s\t%s\t%s\t%s\n' "$case_name" "$run" "$status" "$tactic_ms" >> "$results"
    printf '%-24s run %s: %-4s %6sms\n' "$case_name" "$run" "$status" "$tactic_ms"
  done
done

# The import-only case has no goal, so it is start-up cost rather than a result.
printf '\nSolved (excluding the import-only case):\n'
awk -F '\t' -v repeats="$repeats" '
  NR > 1 && $1 != "00_import_only" {
    cases[$1] = 1
    if ($3 == "pass") passed[$1] += 1
  }
  END {
    solved = 0; count = 0
    for (c in cases) { count += 1; if (passed[c] == repeats) solved += 1 }
    printf "%d/%d\n", solved, count
  }
' "$results"
