# Data Filtering

## Overview

The Data Filtering page from DougSpeed.com explains six primary options available in most LDAK commands for filtering predictors and samples.

## Filtering Options

### Predictor Filtering

**`--extract <extractfile>`** — Restricts analysis to predictors listed in the specified file.

**`--exclude <excludefile>`** — Removes predictors listed in the file from analysis. This setting takes priority over `--extract`.

**`--chr <integer>`** — Limits analysis to a single chromosome. Special keywords include:
- `AUTO` for chromosomes 1-22 (autosomes in humans)
- `ODD` or `EVEN` for odd or even chromosomes

**`--snp <predname>`** — Analyzes only a specific named predictor.

### Sample Filtering

**`--keep <keepfile>`** — Includes only samples specified in the file.

**`--remove <removefile>`** — Excludes samples listed in the file. This setting takes priority over `--keep`.

### Phenotype Filtering

**`--pheno <phenofile>`** — Available for many commands; restricts analysis to samples with available phenotype data.

## Quality Control Filtering

For filtering based on quality metrics (minor allele frequency, variance, missingness, information score), the documentation recommends:

1. Generate a list of predictors or samples meeting your criteria
2. Use `--extract` and `--keep` options with that list
3. Alternatively, remake the dataset with appropriate filters applied
