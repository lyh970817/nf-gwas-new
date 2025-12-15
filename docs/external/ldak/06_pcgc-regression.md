# PCGC Regression

**Home:** [DougSpeed.com](https://dougspeed.com/)

---

## Overview

PCGC (phenotype-correlation genotype-correlation) Regression provides an alternative to REML for estimating heritability in binary traits (diseases). Developed by Golan, Lander and Rosset, then further refined by Weissbrod, Flint and Rossett, this method offers two key advantages:

1. Estimates heritability on the liability scale (more suitable for binary outcomes)
2. Corrects for ascertainment bias caused by case oversampling

The LDAK implementation includes support for regions and sample subsets. Users should adjust kinship matrices before including covariates.

---

## Main Arguments

**Primary command:** `--pcgc <outfile>`

### Required Options
- `--pheno <phenofile>` — Phenotypes in PLINK format
- `--prevalence <float>` — Population prevalence specification

### Common Additional Options
- `--grm <kinfile>` or `--mgrm <kinstems>` — Kinship matrices
- `--region-number <integer>` and `--region-prefix <regprefix>` — Regional analysis
- `--bfile/--gen/--sp/--speed <datastem>` — Genetic data files
- `--power <float>` — Predictor scaling
- `--covar <covarfile>` or `--factors <factorfile>` — Fixed effect covariates
- `--top-preds <toppredslist>` — Highly-associated predictors as fixed effects
- `--keep <keepfile>` and/or `--remove <removefile>` — Sample filtering
- `--memory-save YES` — Read kinship matrices on-the-fly

---

## Output Files

- **`<outfile>.pcpc`** — Heritability estimates by kinship matrix, region, and top predictors (liability scale); includes intensity metrics
- **`<outfile>.share`** — Fraction of heritability explained; enrichment estimates
- **`<outfile>.pcgc.within`** and **`<outfile>.pcgc.across`** — Subset-specific results (when using sample subsets)
- **`<outfile>.pcgc.compare`** — Likelihood ratio test results comparing subset estimates
- **`<outfile>.pcgc.marginal`** — Marginal heritabilities including covariate contribution

---

## Examples

### Basic Analysis
```
./ldak.out --pcgc pcgc1 --pheno binary.pheno --grm HumDef --prevalence .01
```
Result: Heritability estimate of 0.24 (SD 0.11)

### With Regional Analysis
```
./ldak.out --pcgc pcgc2 --pheno binary.pheno --grm HumDef --prevalence .01 \
  --region-prefix part --region-number 1 --bfile human --power -.25
```
Results: Kinship matrix heritability 0.18 (SD 0.11); region heritability 0.07 (SD 0.07)

### With Covariates
First adjust the kinship matrix:
```
./ldak.out --adjust-grm HumDef.covar --grm HumDef --covar human.covar
```

Then run PCGC regression:
```
./ldak.out --pcgc pcgc3 --pheno binary.pheno --grm HumDef.covar \
  --prevalence .01 --covar human.covar
```

### With Sample Subsets
```
./ldak.out --pcgc pcgc4 --pheno binary.pheno --grm HumDef --prevalence .01 \
  --subset-prefix ind --subset-number 2
```
Produces comparisons across cohorts; example result shows P=0.43 for difference between within-cohort (0.31, SD 0.13) and across-cohort (0.16, SD 0.15) estimates.

---

## Notes

- Always review screen output for argument suggestions and memory estimates
- Consult [Adjust Kinships](https://dougspeed.com/adjust-kinships/) documentation before including covariates
- By default, PCGC provides conditional heritabilities (discounting covariate effects); marginal estimates appear in separate file
- Highly associated predictors can be included using `--top-preds` to accommodate loci with large effects
