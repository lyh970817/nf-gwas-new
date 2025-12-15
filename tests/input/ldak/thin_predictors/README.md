# Thin Predictors Test Data

Test data for LD-based predictor thinning used by `THIN_PREDICTORS`, `CREATE_THIN_WEIGHTS`, and `CALC_KINS_WEIGHTS` processes.

## Overview

This directory contains outputs from LDAK's predictor thinning process, which selects near-independent SNPs for kinship calculation.

## Files

| File | Description | Size |
|------|-------------|------|
| `example.thin.in` | List of SNPs kept after thinning | 292B |
| `weights.thin` | SNP weights based on LD structure | 5.8K |

## File Formats

### .thin.in file (Thinned SNP list)
```
SNP_ID
rs12345
rs67890
...
```

### weights.thin file (SNP weights)
```
SNP_ID    Weight
rs12345   1.000
rs67890   0.850
rs11111   1.230
...
```

Weights reflect the inverse of LD tagging - SNPs in low-LD regions get higher weights.

## Data Generation

Generated from:
- Input: `tests/input/example.{bed,bim,fam}`
- Using `THIN_PREDICTORS` process (for .thin.in)
- Using `CREATE_THIN_WEIGHTS` process (for weights.thin)

## Usage in Tests

### THIN_PREDICTORS Test
```groovy
input[0] = tuple(
    1,
    "example",
    file("example.bed"),
    file("example.bim"),
    file("example.fam"),
    null
)
// Output: example.thin.in
```

### CREATE_THIN_WEIGHTS Test
```groovy
input[0] = file("example.thin.in")
// Output: weights.thin
```

### CALC_KINS_WEIGHTS Test
```groovy
input[0] = tuple(
    1,
    "example",
    file("example.bed"),
    file("example.bim"),
    file("example.fam"),
    null
)
input[1] = file("weights.thin")
```

## Why LD-Based Weighting?

Standard kinship assumes all SNPs are independent, but SNPs in LD are correlated. This causes:
- **Overweighting** of high-LD regions
- **Biased** heritability estimates

LDAK's weighting corrects for this by:
1. Down-weighting SNPs in high-LD regions
2. Up-weighting SNPs in low-LD regions
3. Making kinship estimates more accurate

## Related Documentation

- [THIN_PREDICTORS Module](../../../../modules/local/ldak/thin_predictors.nf)
- [CREATE_THIN_WEIGHTS Module](../../../../modules/local/ldak/create_thin_weights.nf)
- [CALC_KINS_WEIGHTS Module](../../../../modules/local/ldak/calc_kins_weights.nf)
- [LDAK Kinship Reference](../../../../modules/local/ldak/KINSHIP_REFERENCE.md)
