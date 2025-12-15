# Genomic Partitioning

## Overview

Genomic partitioning investigates the genetic architecture of complex traits by estimating heritability contributions from predictor subsets. This approach helps clarify how causal variants distribute across the genome. Subsets are typically disjoint (hence "partitioning"), though overlapping subsets work for analyses like pathway investigations.

## Workflow

### Step 1: Create Subset Files
Create files listing predictors for each subset, named sequentially (e.g., `<prefix>1`, `<prefix>2`, ..., `<prefix>K`). This step is optional when partitioning by chromosome using `--chr <integer>` or `--by-chr YES`.

### Step 2: Calculate Kinship Matrices
Using the Human Default Model, calculate a kinship matrix per subset:
- **Direct method**: Use `--extract <extractfile>` for each subset file
- **Indirect method**: Use `--partition-number K` and `--partition-prefix <prefix>` when cutting

### Step 3: Estimate SNP Heritability
Apply REML, Haseman-Elston, or PCGC Regression using `--mgrm <kinstems>` to provide multiple kinship matrices.

## Example: Direct Method

```bash
for j in {1..3}; do
  ./ldak.out --calc-kins-direct part$j --bfile human --power -.25 --extract part$j
done
```

## Example: Indirect Method

```bash
./ldak.out --cut-kins gp --bfile human --partition-number 3 --partition-prefix part
for j in {1..3}; do
  ./ldak.out --calc-kins gp --bfile human --partition $j --power -.25
done
```

## Example: Chromosome-Based Partitioning

```bash
./ldak.out --cut-kins gp2 --bfile human --by-chr YES
for j in {1..2}; do
  ./ldak.out --calc-kins gp2 --bfile human --partition $j --power -.25
done
```

## Example: REML Analysis

```bash
echo "chr21
chr22" > mlist.txt
./ldak.out --reml reml5 --pheno quant.pheno --mgrm mlist.txt
```

This produces heritability estimates for each chromosome subset in the output file.

---

**Website**: [DougSpeed.com](https://dougspeed.com/)
