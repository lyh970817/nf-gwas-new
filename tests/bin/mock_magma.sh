#!/usr/bin/env bash
set -euo pipefail

out=""
annotate=0
setmode=0

for ((i=1; i<=$#; i++)); do
  arg="${!i}"
  if [[ "$arg" == "--out" ]]; then
    j=$((i+1))
    out="${!j}"
  fi
  if [[ "$arg" == "--annotate" ]]; then
    annotate=1
  fi
  if [[ "$arg" == "--set-annot" ]]; then
    setmode=1
  fi
done

if [[ -z "$out" ]]; then
  echo "mock magma missing --out" >&2
  exit 1
fi

if [[ "$annotate" -eq 1 ]]; then
  cat > "${out}.genes.annot" <<'EOA'
GENE CHR START STOP
GENE1 1 1 200000
GENE2 1 200001 500000
EOA
  exit 0
fi

if [[ "$setmode" -eq 1 ]]; then
  cat > "${out}.gsa.out" <<'EOG'
VARIABLE TYPE NGENES BETA SE P
SET1 SET 2 0.10 0.20 0.50
EOG
  exit 0
fi

cat > "${out}.genes.out" <<'EOGO'
GENE CHR START STOP NSNPS NPARAM ZSTAT P
GENE1 1 1 200000 5 1 2.0 0.0455
EOGO

cat > "${out}.genes.raw" <<'EOGR'
GENE CHR START STOP NSNPS NPARAM ZSTAT P
GENE1 1 1 200000 5 1 2.0 0.0455
EOGR
