# LDAK SumHer Test Data

Test data for LDAK summary statistics methods (SumHer and SumCors).

## Files

### Tagging Files

| File | Columns | Size | Purpose |
|------|---------|------|---------|
| `test_thin.tagging.gz` | 10 | ~2K | LDAK-Thin format for SumCors |
| `test_bld.tagging.gz` | 75 | ~24K | BLD format for SumHer with enrichment |
| `test_thin.tagging` | 10 | 4.5K | Uncompressed version |
| `test_bld.tagging` | 75 | 53K | Uncompressed version |

### Summary Statistics Files

| File | Columns | Description |
|------|---------|-------------|
| `test_gwas_summary.txt` | 5 | GWAS summary stats (trait 1) |
| `test_gwas_summary2.txt` | 5 | GWAS summary stats (trait 2, correlated) |

## Tagging File Format

### Thin Format (10 columns)
```
Predictor  A1  A2  Neighbours  Tagging  Weight  MAF  Categories  Exp_Heritability  Base
1          A   G   234         7.859    1       0.046 1          0.00004           7.87
```

### BLD Format (75 columns)
```
Predictor  A1  A2  Neighbours  Tagging  Weight  MAF  Categories  Exp_Heritability  Annotation_1...Annotation_65  Base
1          A   G   234         7.859    1       0.046 21         0.496             [65 annotation values]        ...
```

## Summary Statistics Format
```
Predictor  A1  A2  n      Z
1          A   G   10000  -1.5105
2          A   C   10000  1.2873
```

## Data Generation

Files were generated using `create_dummy_tagging.R`:
- 100 SNPs with numeric IDs (1-100) matching test data format
- Realistic value ranges based on actual LDAK tagging files
- Two correlated summary statistics files for genetic correlation testing

## Usage in Tests

### SumHer Heritability Test
```groovy
input[0] = [["trait1", file("test_gwas_summary.txt")]]
input[1] = file("test_bld.tagging.gz")  // or test_thin.tagging.gz
```

### SumCors Genetic Correlation Test
```groovy
input[0] = [["trait1", file("test_gwas_summary.txt"), "trait2", file("test_gwas_summary2.txt")]]
input[1] = file("test_thin.tagging.gz")
```

## Related Files

- [LDAK Modules](../../../../modules/local/ldak/CLAUDE.md)
- [LDAK Workflows](../../../../workflows/ldak/CLAUDE.md)
- [LDAK Heritability Reference](../../../../modules/local/ldak/HERITABILITY_REFERENCE.md)

## Notes

- SNP IDs are numeric (1, 2, 3, ...) to match nf-gwas test data convention
- Files are small for fast test execution
- Both compressed (.gz) and uncompressed versions provided for flexibility
