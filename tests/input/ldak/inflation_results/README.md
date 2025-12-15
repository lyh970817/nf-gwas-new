# Inflation Test Results

Test data for genomic inflation testing output from `CALC_INFLATION` process.

## Overview

This directory contains the output of genomic inflation calculation, which detects potential genotype errors or population stratification.

## Files

| File | Description | Size |
|------|-------------|------|
| `inflation_results.txt` | Inflation statistics | 901B |

## Inflation Results Format

```
Full_h2       Full_SE   Quarter_Mean_h2   Quarter_SE   Inflation   Inflation_SE   P_value
0.324         0.089     0.318             0.092        1.019       0.021          0.365
```

### Columns
| Column | Description |
|--------|-------------|
| `Full_h2` | Heritability from full genome |
| `Full_SE` | Standard error of full h² |
| `Quarter_Mean_h2` | Mean h² from quarter analyses |
| `Quarter_SE` | Standard error of quarter mean |
| `Inflation` | Ratio of full to quarter h² |
| `Inflation_SE` | Standard error of inflation |
| `P_value` | Test for inflation significantly > 1 |

## Usage in Tests

### CALC_INFLATION Test
```groovy
// Full genome REML result
input[0] = file("reml_results/reml_ldak_grm.reml")
// Quarter/chromosome REML results
input[1] = [
    file("reml_results/reml_chr01.vcf.reml"),
    file("reml_results/reml_chr02.vcf.reml")
]
```

## Interpreting Inflation

| Inflation Value | Interpretation |
|-----------------|----------------|
| ~1.00 | No inflation (good) |
| 1.05-1.10 | Mild inflation |
| > 1.10 | Significant inflation (investigate) |
| < 0.95 | Deflation (potential issue) |

### Causes of Inflation
- Genotype errors
- Population stratification
- Cryptic relatedness (unfiltered)
- Sample contamination

## Related Documentation

- [CALC_INFLATION Module](../../../../modules/local/ldak/calc_inflation.nf)
- [LDAK QC Reference](../../../../modules/local/ldak/QC_REFERENCE.md)
