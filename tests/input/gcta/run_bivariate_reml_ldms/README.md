# RUN_BIVARIATE_REML_LDMS Test Data

Test input files for the `RUN_BIVARIATE_REML_LDMS` process module.

## Overview

This directory contains self-contained test data for bivariate REML-LDMS analysis
using the multi-GRM input mechanism (via mgrm file).

**Note**: Full LDMS testing with multiple LD-stratified GRMs requires larger datasets
that exceed test data constraints. This test validates the mgrm input mechanism with
a single GRM for basic functionality. Complete LDMS workflow testing should be done
at the workflow level with real data.

## Files

| File | Description | Source |
|------|-------------|--------|
| `gcta_grm.mgrm` | Multi-GRM file listing GRM prefix | Created for test |
| `gcta_grm.grm.id` | GRM sample IDs | Copied from `run_reml_ldms/` |
| `gcta_grm.grm.bin` | GRM binary matrix | Copied from `run_reml_ldms/` |
| `gcta_grm.grm.N.bin` | GRM N matrix | Copied from `run_reml_ldms/` |
| `phenotype.noheader.txt` | Two-trait phenotype file (FID, IID, Y1, Y2) | Copied from `prepare_phenocov/` |
| `covariates.quant.noheader.txt` | Quantitative covariates | Copied from `prepare_phenocov/` |
| `covariates.cat.noheader.txt` | Categorical covariates | Copied from `prepare_phenocov/` |

## Process Details

- **Process**: `RUN_BIVARIATE_REML_LDMS`
- **Module**: `modules/local/gcta/run_bivariate_reml_ldms.nf`
- **Tool**: GCTA
- **Command**: `gcta --reml-bivar 1 2 --mgrm <file> --pheno <file> --reml-bivar-no-constrain`

## Test Coverage

1. **mgrm input mechanism**: Validates that process correctly handles mgrm file input

## Related Tests

- `run_bivariate_reml/`: Single-GRM bivariate REML
- `run_reml_ldms/`: Univariate REML-LDMS for single trait
