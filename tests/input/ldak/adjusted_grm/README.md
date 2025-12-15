# Adjusted GRM Test Data

Test data for covariate-adjusted kinship matrix used by LDAK heritability estimation processes.

## Overview

This directory contains the GRM after covariate adjustment via `ADJUST_GRM_LDAK`. The adjusted GRM is required for:
- `LDAK_HE` - Haseman-Elston regression
- `LDAK_PCGC` - PCGC liability-scale heritability

**Note**: The `.grm.root` file is critical for HE/PCGC methods as it stores covariate information needed for proper inference.

## Files

| File | Description | Size |
|------|-------------|------|
| `ldak_grm_adj.grm.bin` | Binary adjusted kinship matrix | 501K |
| `ldak_grm_adj.grm.id` | Sample IDs (FID IID format) | 3.7K |
| `ldak_grm_adj.grm.details` | SNP-level details | 60K |
| `ldak_grm_adj.grm.adjust` | Adjustment factors | 123B |
| `ldak_grm_adj.grm.root` | **Covariate root file** (required for HE/PCGC) | 96B |

## Data Generation

Generated from `ADJUST_GRM_LDAK` process with:
- Input: `combined_grm/ldak_grm.*` files
- Phenotype: `phenotype.noheader.txt`
- Quantitative covariates: `covariates.quant.noheader.txt`

## Usage in Tests

### LDAK_HE Test (6-tuple with root file)
```groovy
input[0] = tuple(
    "ldak_grm_adj",
    file("ldak_grm_adj.grm.bin"),
    file("ldak_grm_adj.grm.id"),
    file("ldak_grm_adj.grm.details"),
    file("ldak_grm_adj.grm.adjust"),
    file("ldak_grm_adj.grm.root")  // Required!
)
```

### LDAK_PCGC Test (6-tuple with root file)
```groovy
input[0] = tuple(
    "ldak_grm_adj",
    file("ldak_grm_adj.grm.bin"),
    file("ldak_grm_adj.grm.id"),
    file("ldak_grm_adj.grm.details"),
    file("ldak_grm_adj.grm.adjust"),
    file("ldak_grm_adj.grm.root")  // Required!
)
```

## Why Adjustment Matters

LDAK's `--adjust-grm` accounts for covariates by:
1. Regressing phenotype on covariates
2. Storing residual structure in `.grm.root`
3. Using this for proper heritability estimation

Without adjustment, heritability estimates may be confounded by covariates like age, sex, and population structure.

## Related Documentation

- [ADJUST_GRM_LDAK Module](../../../../modules/local/ldak/adjust_grm.nf)
- [LDAK Heritability Reference](../../../../modules/local/ldak/HERITABILITY_REFERENCE.md)
