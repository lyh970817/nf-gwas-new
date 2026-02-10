#!/usr/bin/env bash
set -euo pipefail

out=""
mode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      out="$2"; shift 2 ;;
    --h2)
      mode="h2"; shift 2 ;;
    --rg)
      mode="rg"; shift 2 ;;
    *)
      shift ;;
  esac
done

if [[ -z "$out" ]]; then
  echo "ERROR: mock ldsc.py requires --out" >&2
  exit 2
fi

if [[ "$mode" == "h2" ]]; then
  cat <<LOG > "${out}.log"
Total Observed scale h2: 0.2100 (0.0300)
LOG
elif [[ "$mode" == "rg" ]]; then
  base_out="$(basename "$out")"
  trait1="${base_out%%.*}"
  rest="${base_out#*.}"
  trait2="${rest%%.*}"
  cat <<LOG > "${out}.log"
p1 p2 rg se z p
${trait1} ${trait2} 0.3500 0.0700 5.0000 0.000001
LOG
else
  echo "ERROR: mock ldsc.py expected --h2 or --rg" >&2
  exit 2
fi
