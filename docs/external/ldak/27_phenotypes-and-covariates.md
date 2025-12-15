# Phenotypes and Covariates

## Overview

Phenotype files must follow [PLINK format](https://www.cog-genomics.org/plink/2.0/input#pheno), with the first two columns containing sample IDs and subsequent columns holding phenotype values. Files may include a header row, provided the first two elements are labeled FID & IID or ID1 & ID2.

## Multiple Phenotypes

When a phenotype file contains more than one phenotype, use `--mpheno <integer>` to select which phenotype to analyze. For example, `--mpheno 2` analyzes the second phenotype in the fourth column.

Some functions, including LDAK-KVIK and REML, support `--mpheno ALL` to test all phenotypes simultaneously.

## Missing and Binary Phenotypes

Missing phenotypic values should be marked as NA. Note that LDAK differs from PLINK—only NA denotes missing values, not -9.

Binary phenotypes must use values: 0 (control), 1 (case), or NA (missing). By default, LDAK excludes samples with missing phenotypes, though this behavior differs when analyzing multiple phenotypes, where missing values are replaced with the phenotype mean.

---

## Covariates

Covariate files also follow [PLINK format](https://www.cog-genomics.org/plink/2.0/input#pheno), with sample IDs in the first two columns and covariate values in subsequent columns.

### Quantitative vs. Categorical

- Use `--covar` for quantitative covariates
- Use `--factors` for categorical covariates

For categorical variables with U unique values, LDAK internally converts them to U-1 indicator variables. An error occurs if the total number of indicator variables exceeds half the sample size.

### Selecting Covariates

For quantitative covariates, `--covar-numbers` specifies a subset using commas and dashes. For example: `--covar-numbers 1,2,4-6,8` retains covariates 1, 2, 4, 5, 6, and 8.

When headers exist, use `--covar-names` with comma-separated values.

### Missing Covariate Values

Missing covariate values must be denoted as NA and are replaced with the corresponding covariate mean.
