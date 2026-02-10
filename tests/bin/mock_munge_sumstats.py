#!/usr/bin/env bash
set -euo pipefail

sumstats=""
out=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sumstats)
      sumstats="$2"; shift 2 ;;
    --out)
      out="$2"; shift 2 ;;
    *)
      shift ;;
  esac
done

if [[ -z "$sumstats" || -z "$out" ]]; then
  echo "ERROR: mock munge_sumstats.py requires --sumstats and --out" >&2
  exit 2
fi

cat "$sumstats" | gzip -c > "${out}.sumstats.gz"
cat <<LOG > "${out}.log"
Mock munge_sumstats run for ${out}
Input file: ${sumstats}
LOG
