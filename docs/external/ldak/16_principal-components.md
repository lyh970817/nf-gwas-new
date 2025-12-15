# Principal Components

## Overview

The DougSpeed.com website provides documentation on performing principal component analysis (PCA) using LDAK software. PCA is commonly employed for quality control purposes, detecting outliers within datasets, or constructing population covariates.

## Performing Principal Component Analysis

The main command uses `--pca <outfile>` with required options:

- `--grm <kinfile>` — provides a kinship matrix
- `--axes <integer>` — specifies the number of axes (typically 20)

This generates two output files:
- `<outfile>.vect` — leading axes
- `<outfile>.values` — corresponding eigenvalues

The `.vect` file can serve as covariates in subsequent analyses like REML, Haseman Elston, or PCGC Regression by using `--covar <outfile>.vect`.

## Calculating Predictor Loadings

Use `--calc-pca-loads <outfile>` with these required options:

- `--pcastem <pcastem>` — stem of previous PCA results
- `--grm <kinfile>` — kinship matrix from PCA
- `--bfile/--gen/--sp/--speed <datastem>` or `--bgen <datafile>` — genetic data files

This produces:
- `<outfile>.load` — predictor loadings
- `<outfile>.proj` — projections of genetic data

## Example Workflow

Using test data files (human.bed, human.bim, human.fam) and kinship matrix (HumDef):

```
./ldak.out --pca HumDef --grm HumDef --axes 20
```

Then calculate loadings:

```
./ldak.out --calc-pca-loads HumDef --pcastem HumDef --grm HumDef --bfile human
```

---

*Site:* [DougSpeed.com](https://dougspeed.com/) | Powered by WordPress
