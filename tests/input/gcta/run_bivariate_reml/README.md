# RUN_BIVARIATE_REML Test Data

Test input files for the `RUN_BIVARIATE_REML` process module.

## Overview

This directory contains self-contained test data for bivariate REML analysis
to estimate genetic correlation between two traits using a single GRM.

## Files

| File | Description | Source |
|------|-------------|--------|
| `gcta_grm_0.grm.id` | GRM sample IDs | Copied from `remove_related_subjects/` |
| `gcta_grm_0.grm.bin` | GRM binary matrix | Copied from `remove_related_subjects/` |
| `gcta_grm_0.grm.N.bin` | GRM N matrix | Copied from `remove_related_subjects/` |
| `phenotype.noheader.txt` | Two-trait phenotype file (FID, IID, Y1, Y2) | Copied from `prepare_phenocov/` |
| `covariates.quant.noheader.txt` | Quantitative covariates | Copied from `prepare_phenocov/` |
| `covariates.cat.noheader.txt` | Categorical covariates | Copied from `prepare_phenocov/` |

## Process Details

- **Process**: `RUN_BIVARIATE_REML`
- **Module**: `modules/local/gcta/run_bivariate_reml.nf`
- **Tool**: GCTA
- **Command**: `gcta --reml-bivar 1 2 --grm <prefix> --pheno <file>`

## Test Coverage

1. **Basic bivariate REML**: Single GRM, two phenotypes, no covariates
2. **With covariates**: Single GRM, two phenotypes, quantitative covariates

## Related Tests

- `run_bivariate_reml_ldms/`: Multi-GRM bivariate REML (LD-stratified)
- `run_reml/`: Univariate REML for single trait
