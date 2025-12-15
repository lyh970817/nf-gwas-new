# Filtered Relatedness Test Data

Test data for relatedness filtering output used by LDAK heritability processes.

## Overview

This directory contains the output from `FILTER_RELATEDNESS`, which identifies related individuals to exclude from heritability analysis to avoid bias.

## Files

| File | Description | Size |
|------|-------------|------|
| `ldak_grm.keep` | Sample IDs to keep (unrelated) | 3.7K |
| `ldak_grm.lose` | Sample IDs to remove (related) | 40B |
| `ldak_grm.maxrel` | Maximum relatedness value found | 9B |

**Note**: The output files use the same prefix as the input GRM (`ldak_grm`) for consistency. This allows the `.keep` file to be found at `{grm_prefix}.keep` when loading pre-computed GRMs.

## File Format

### .keep file
```
FID IID
sample1 sample1
sample2 sample2
...
```

### .lose file
```
FID IID
related1 related1
...
```

### .maxrel file
```
0.354
```
Contains the maximum kinship value threshold used.

## Data Generation

Generated from `FILTER_RELATEDNESS` process:
- Input: `combined_grm/ldak_grm.*` files
- Default threshold: kinship > 0.354 (first-degree relatives)
- ~498 samples kept, ~2 samples removed

## Usage in Tests

### LDAK_REML Test
```groovy
input[1] = tuple(
    "ldak_grm",
    file("ldak_grm.keep"),
    file("ldak_grm.lose"),
    file("ldak_grm.maxrel")
)
```

### LDAK_HE / LDAK_PCGC Tests
```groovy
input[1] = tuple(
    "ldak_grm",
    file("ldak_grm.keep"),
    file("ldak_grm.lose"),
    file("ldak_grm.maxrel")
)
```

## Why Filtering Matters

Related individuals share genetic similarity beyond what's expected in the population, which:
1. Inflates heritability estimates
2. Violates assumptions of REML/HE methods
3. Can cause numerical instability

LDAK recommends filtering at kinship > 0.354 (equivalent to first-degree relatives).

## Related Documentation

- [FILTER_RELATEDNESS Module](../../../../modules/local/ldak/filter_relatedness.nf)
- [LDAK QC Reference](../../../../modules/local/ldak/QC_REFERENCE.md)
