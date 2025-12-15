# REML Test Results

Test data for REML variance estimation outputs from `LDAK_REML` and `CALC_INFLATION` processes.

## Overview

This directory contains REML (Restricted Maximum Likelihood) results for heritability estimation and genomic inflation testing.

## Files

### Full-Genome REML Results
| File | Description | Size |
|------|-------------|------|
| `reml_ldak_grm.reml` | Main REML result | 509B |
| `reml_ldak_grm.coeff` | Coefficient estimates | 201B |
| `reml_ldak_grm.combined` | Combined statistics | 16K |
| `reml_ldak_grm.cross` | Cross-validation | 18B |
| `reml_ldak_grm.indi.blp` | Individual BLUPs | 13K |
| `reml_ldak_grm.indi.res` | Individual residuals | 17K |
| `reml_ldak_grm.progress` | Iteration progress | 506B |
| `reml_ldak_grm.share` | Sharing statistics | 96B |
| `reml_ldak_grm.vars` | Variance components | 71B |

### Per-Chromosome REML Results (for Inflation Testing)
| File | Description | Size |
|------|-------------|------|
| `reml_chr01.vcf.reml` | Chr1 REML result | 513B |
| `reml_chr02.vcf.reml` | Chr2 REML result | 513B |

## REML Result Format (.reml file)

```
Component     Category   Var_K1    SD        Her_K1    Her_K1_SD
Her_K1        Kinship    0.324     0.089     0.324     0.089
Her_K2        Residual   0.676     0.089     0.676     0.089
Total         -          1.000     -         1.000     -
Iterations    -          18        -         -         -
LogLikelihood -          -1254.3   -         -         -
Num_Samples   -          498       -         -         -
Num_Covariates -         0         -         -         -
```

## Usage in Tests

### LDAK_REML Test
```groovy
input[0] = tuple(
    "ldak_grm",
    file("combined_grm/ldak_grm.grm.bin"),
    ...
)
input[1] = tuple(
    "ldak_grm_filtered",
    file("filtered/ldak_grm_filtered.keep"),
    ...
)
input[2] = file("phenotype.noheader.txt")
input[3] = []  // Optional covariates
input[4] = []  // Optional categorical covariates
```

### CALC_INFLATION Test
```groovy
// Full genome REML
input[0] = file("reml_ldak_grm.reml")
// Per-chromosome REML results (used as "quarter" results)
input[1] = [
    file("reml_chr01.vcf.reml"),
    file("reml_chr02.vcf.reml")
]
```

## Inflation Testing

Genomic inflation is assessed by comparing:
- **Full genome h²**: Using all chromosomes
- **Leave-one-out h²**: Excluding each chromosome in turn

Significant differences indicate genotype error or population stratification.

## Related Documentation

- [LDAK_REML Module](../../../../modules/local/ldak/ldak_reml.nf)
- [CALC_INFLATION Module](../../../../modules/local/ldak/calc_inflation.nf)
- [LDAK Heritability Reference](../../../../modules/local/ldak/HERITABILITY_REFERENCE.md)
