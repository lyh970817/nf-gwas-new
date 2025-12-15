# HE Regression Test Results

Test data for Haseman-Elston regression outputs used by `CALC_GENOTYPE_ERROR_T2` process.

## Overview

This directory contains HE regression results from `LDAK_HE`, including batch-specific within/across comparisons for genotype error detection.

## Files

### Standard HE Results
| File | Description | Size |
|------|-------------|------|
| `he_ldak_grm.he` | HE regression result | 458B |
| `he_ldak_grm.coeff` | Coefficient estimates | 201B |
| `he_ldak_grm.combined` | Combined statistics | 16K |
| `he_ldak_grm.cross` | Cross-validation results | 18B |
| `he_ldak_grm.progress` | Progress log | 36B |
| `he_ldak_grm.share` | Sharing statistics | 96B |

### Adjusted GRM HE Results
| File | Description | Size |
|------|-------------|------|
| `he_ldak_grm_adj.he` | HE result with adjusted GRM | 462B |
| `he_ldak_grm_adj.coeff` | Coefficients | 201B |
| `he_ldak_grm_adj.combined` | Combined statistics | 16K |
| `he_ldak_grm_adj.cross` | Cross-validation | 18B |
| `he_ldak_grm_adj.progress` | Progress log | 36B |
| `he_ldak_grm_adj.share` | Sharing statistics | 96B |

### Batch HE Results (for Genotype Error)
| File | Description | Size |
|------|-------------|------|
| `he_batch_grm.he` | Overall HE result | 459B |
| `he_batch_grm.he.within` | Within-batch HE | 459B |
| `he_batch_grm.he.across` | Across-batch HE | 459B |
| `he_batch_grm.he.compare` | Comparison statistics | 113B |
| `he_batch_grm.cross.within` | Within cross-val | 18B |
| `he_batch_grm.cross.across` | Across cross-val | 18B |
| `he_batch_grm.share.within` | Within sharing | 96B |
| `he_batch_grm.share.across` | Across sharing | 96B |

## HE Result Format (.he file)

```
Component  Category  Variance  SD  Her_All  Her_K1
Her_K1     Kinship   0.324     0.089  0.324   0.324
Her_K2     Residual  0.676     0.089  0.676   0.676
Total      -         1.000     -      1.000   1.000
```

## Usage in Tests

### CALC_GENOTYPE_ERROR_T2 Test
```groovy
// Requires within/across comparisons
input[0] = [
    file("he_batch_grm.he"),
    file("he_batch_grm.he.within"),
    file("he_batch_grm.he.across")
]
```

## Genotype Error Detection

The T2 statistic compares within-batch vs across-batch heritability:
- **Within-batch**: Genetic relatedness within genotyping batches
- **Across-batch**: Genetic relatedness between different batches
- **T2 = h²_within - h²_across**: Differences indicate genotype error

## Related Documentation

- [LDAK_HE Module](../../../../modules/local/ldak/ldak_he.nf)
- [CALC_GENOTYPE_ERROR_T2 Module](../../../../modules/local/ldak/calc_genotype_error_t2.nf)
- [LDAK Heritability Reference](../../../../modules/local/ldak/HERITABILITY_REFERENCE.md)
