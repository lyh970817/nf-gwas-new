# Calculate Scores

## Overview

This page explains how to calculate linear combinations of predictor values (projections of genetic data onto predictor effect sizes). The primary application is creating polygenic risk scores (PRS), though it can also be used for quality control purposes, such as inferring individual ancestry by projecting data onto population axes.

**Important:** Always review the screen output, which provides argument suggestions and memory usage estimates.

---

## Main Command

The primary argument is `--calc-scores <outfile>`.

### Required Options

- **`--scorefile <scorefile>`** - Provides predictor effect sizes. The score file must contain 4+M columns (M = number of effect size sets). The first four columns should include: predictor name, A1 allele, A2 allele, and mean A1 allele count. Remaining columns contain effect size sets. The header row must begin with "Predictor", "A1", "A2", "Centre". If predictor means are unknown, use "NA" (LDAK will center based on mean A1 allele count in genetic data).

- **`--bfile/--gen/--sp/--speed <prefix>` or `--bgen <datafile>`** - Specifies genetic data files (see File Formats documentation).

- **`--power <float>`** - Specifies predictor scaling. Use `--power 0` for raw effects; `--power -1` for standardized effects.

### Optional Options

- **`--pheno <phenofile>`** - Provides phenotypes for genetic dataset individuals. LDAK calculates correlation between scores and phenotypes.

- **`--summary <sumsfile>`** - Provides summary statistics from association studies. LDAK estimates PRS-phenotype correlation using genetic data as a reference panel.

- **`--PRS-variance YES`** - Use when score file was created with MegaPRS using this option.

- **`--final-effects <finaleffectsfile>`** - Allows specification of two prediction model sets. LDAK saves the second set's model corresponding to the first set's most accurate model.

- **`--hwe-stand NO`** - Uses variance from genetic data instead of Hardy-Weinberg equilibrium assumptions.

---

## Output

Scores are saved in `<outfile>.profile` with 4+2M columns. For M=2 effect size sets:
- Columns 5 & 7 contain scores
- Columns 6 & 8 are blank by default, or contain standard deviations if `--PRS-variance YES` is used

---

## Formula

For m predictors, Sample i's score is calculated as:

```
Pi = b₁(Xi₁ - c₁)(c₁(1-c₁/2))^(power/2) + ... + bₘ(Xiₘ - cₘ)(cₘ(1-cₘ/2))^(power/2)
```

Where:
- **Xij** = Sample i's value for Predictor j
- **cj** = center of Predictor j
- **bj** = effect size of Predictor j
- **power** = scaling parameter

For SNPs, cj/2 estimates allele frequency; cj(1-cj/2) represents expected variance under Hardy-Weinberg equilibrium.

When `--power=0`:
```
Pi = b₁(Xi₁ - c₁) + ... + bₘ(Xiₘ - cₘ)
```

With `--hwe-stand NO`, the formula uses:
```
Pi = b₁(Xi₁ - c₁)v₁^(power/2) + ... + bₘ(Xiₘ - cₘ)vₘ^(power/2)
```

Where **vj** = variance of Predictor j in genetic data.

---

## Example

Using binary PLINK files (human.bed, human.bim, human.fam) and phenotype file (quant.pheno):

**Create score file:**
```bash
echo "Predictor A1 A2 Centre Effect1 Effect2
21:14642464 A G 0.88 0.3 -0.1
21:14649798 C A 0.97 -0.2 0.4" > scores.txt
```

**Calculate scores:**
```bash
./ldak.out --calc-scores scores --scorefile scores.txt --bfile human --power 0
```

For first profile: `Pi = 0.3(Xi₁ - 0.88) + -0.2(Xi₂ - 0.97)`

For second profile: `Pi = -0.1(Xi₁ - 0.88) + 0.4(Xi₂ - 0.97)`

**With phenotypes:**
```bash
./ldak.out --calc-scores scores --scorefile scores.txt --bfile human --power 0 --pheno quant.pheno
```

This generates `scores.cors` reporting score-phenotype correlations.
