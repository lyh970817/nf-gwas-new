# Combined GRM Test Data

Test data for combined (genome-wide) kinship matrix used by multiple LDAK processes.

## Overview

This directory contains a genome-wide LDAK kinship matrix created by combining per-chromosome GRMs. It is the primary input for:
- `ADJUST_GRM_LDAK` - Covariate adjustment
- `FILTER_RELATEDNESS` - Relatedness filtering
- `LDAK_REML` - REML variance estimation

## Files

| File | Description | Size |
|------|-------------|------|
| `ldak_grm.grm.bin` | Binary kinship matrix (N×N) | 501K |
| `ldak_grm.grm.id` | Sample IDs (FID IID format) | 3.7K |
| `ldak_grm.grm.details` | SNP-level details | 60K |
| `ldak_grm.grm.adjust` | Adjustment factors | 123B |

## Data Generation

Generated from `ADD_GRMS` process combining:
- Per-chromosome GRMs from `per_chr_grm/`
- 500 samples
- ~1000 total variants (2 chromosomes)

## Usage in Tests

### FILTER_RELATEDNESS Test
```groovy
input[0] = tuple(
    "ldak_grm",
    file("ldak_grm.grm.bin"),
    file("ldak_grm.grm.id"),
    file("ldak_grm.grm.details"),
    file("ldak_grm.grm.adjust")
)
```

### LDAK_REML Test
```groovy
input[0] = tuple(
    "ldak_grm",
    file("ldak_grm.grm.bin"),
    file("ldak_grm.grm.id"),
    file("ldak_grm.grm.details"),
    file("ldak_grm.grm.adjust")
)
// Plus filtered list, phenotype, covariates
```

### ADJUST_GRM_LDAK Test
```groovy
input[0] = tuple(
    "ldak_grm",
    file("ldak_grm.grm.bin"),
    file("ldak_grm.grm.id"),
    file("ldak_grm.grm.details"),
    file("ldak_grm.grm.adjust")
)
input[1] = file("phenotype.noheader.txt")
input[2] = file("covariates.quant.noheader.txt")
input[3] = []  // Empty for no categorical covariates
```

## Related Documentation

- [ADD_GRMS Module](../../../../modules/local/ldak/add_grms.nf)
- [LDAK Kinship Reference](../../../../modules/local/ldak/KINSHIP_REFERENCE.md)
