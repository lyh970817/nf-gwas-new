# PCGC Regression Test Results

Test data for PCGC regression outputs from `LDAK_PCGC` process.

## Overview

This directory contains PCGC (Principal Components of Genomic Covariance) regression results for liability-scale heritability estimation of binary traits.

## Files

### Standard PCGC Results
| File | Description | Size |
|------|-------------|------|
| `pcgc_ldak_grm.pcgc` | PCGC regression result | 462B |
| `pcgc_ldak_grm.pcgc.marginal` | Marginal heritability | 462B |
| `pcgc_ldak_grm.coeff` | Coefficient estimates | 203B |
| `pcgc_ldak_grm.combined` | Combined statistics | 16K |
| `pcgc_ldak_grm.cross` | Cross-validation | 18B |
| `pcgc_ldak_grm.progress` | Progress log | 36B |
| `pcgc_ldak_grm.share` | Sharing statistics | 96B |

### Adjusted GRM PCGC Results
| File | Description | Size |
|------|-------------|------|
| `pcgc_ldak_grm_adj.pcgc` | PCGC with adjusted GRM | 466B |
| `pcgc_ldak_grm_adj.pcgc.marginal` | Marginal heritability | 466B |
| `pcgc_ldak_grm_adj.coeff` | Coefficients | 203B |
| `pcgc_ldak_grm_adj.combined` | Combined statistics | 16K |
| `pcgc_ldak_grm_adj.cross` | Cross-validation | 18B |
| `pcgc_ldak_grm_adj.progress` | Progress log | 36B |
| `pcgc_ldak_grm_adj.share` | Sharing statistics | 96B |

## PCGC Result Format (.pcgc file)

```
Component      Category  Variance  SD     Her_All  Her_K1  Liability
Her_K1         Kinship   0.245     0.098  0.245    0.245   0.312
Her_K2         Residual  0.755     0.098  0.755    0.755   0.688
Total          -         1.000     -      1.000    1.000   1.000
Liability_Her  -         -         -      -        -       0.312
```

## Usage in Tests

### LDAK_PCGC Test
```groovy
params {
    phenotypes_columns = 'Y1'
    ldak_pcgc_prevalence = 0.2  // Required for liability scale
}
process {
    input[0] = tuple(
        "ldak_grm_adj",
        file("adjusted_grm/ldak_grm_adj.grm.bin"),
        ...
        file("adjusted_grm/ldak_grm_adj.grm.root")
    )
    input[1] = tuple(
        "ldak_grm_filtered",
        file("filtered/ldak_grm_filtered.keep"),
        ...
    )
    input[2] = file("phenotype_bin.txt")  // Binary phenotype
}
```

## PCGC vs HE for Binary Traits

| Method | Scale | Best For |
|--------|-------|----------|
| HE | Observed | Quantitative traits |
| PCGC | Liability | Binary (case-control) traits |

PCGC converts observed-scale heritability to liability-scale using disease prevalence.

## Related Documentation

- [LDAK_PCGC Module](../../../../modules/local/ldak/ldak_pcgc.nf)
- [LDAK Heritability Reference](../../../../modules/local/ldak/HERITABILITY_REFERENCE.md)
