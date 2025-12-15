# Manipulate Kinships

## Overview

LDAK provides functionality to both add and subtract kinship matrices. These tools are particularly useful when constructing complementary kinship matrices, such as for leave-one-chromosome-out (LOCO) mixed-model analysis. A typical workflow involves creating per-chromosome kinship matrices, joining them into a genome-wide matrix, then subtracting individual chromosome contributions.

**Important:** Always review the screen output, which suggests appropriate arguments and estimates memory requirements.

---

## Add Kinship Matrices

**Main argument:** `--add-grm <outfile>`

**Required option:**
- `--mgrm <kinstems>` — Specifies kinship matrices to combine

LDAK will sum the specified kinship matrices and save the result with the given stem.

---

## Subtract Kinship Matrices

**Main argument:** `--sub-grm <output>`

**Use either:**

1. `--mgrm <kinstems>` — Provides multiple kinship matrices
   - LDAK subtracts matrices 2 through K from the first matrix

2. `--grm <kinship>` with `--extract <extractfile>` or `--exclude <excludefile>`
   - Removes contributions from specified or excluded predictors
   - Requires genetic data files via `--bfile/--gen/--sp/--speed` or `--bgen`

The resulting kinship matrix is saved with stem `<outfile>`.

---

## Example Workflow

Using test datasets (human.bed, human.bim, human.fam):

**Step 1:** Obtain thinned predictors in linkage equilibrium
```
./ldak.out --thin le --bfile human --window-prune .05 --window-cm 1
./ldak.out --calc-kins-direct le --bfile human --ignore-weights YES --power -1 --extract le.in
```

**Step 2:** Create per-chromosome kinship matrices
```
for j in {21..22}; do
  ./ldak.out --calc-kins-direct le$j --bfile human --ignore-weights YES --power -1 --extract le.in --chr $j
done
```

**Step 3:** Combine into genome-wide matrix
```
rm list.All
for j in {21..22}; do echo "le$j" >> list.All; done
./ldak.out --add-grm leAll --mgrm list.All
```

**Step 4:** Create complementary matrices via subtraction
```
for j in {21..22}; do
  echo "leAll" > list.$j
  echo "le$j" >> list.$j
  ./ldak.out --sub-grm leN$j --mgrm list.$j
done
```

Complementary kinship matrices are saved as leN21 and leN22.

**Alternative approach:**
```
rm chr{1..22}; awk < human.bim '{print $2 > "chr"$1}'
for j in {21..22}; do
  ./ldak.out --sub-grm leN$j --grm leAll --exclude chr$j --bfile human
done
```
