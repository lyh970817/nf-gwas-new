# Calculate Kinships

## Overview

There are two primary approaches to compute a kinship matrix. The direct method is simpler with a single step and works best in most situations. For very large datasets (imputed genotypes for 30,000+ samples), the indirect method with three steps may be more efficient. The indirect approach also benefits genomic partitioning work.

> "the options you use when calculating kinships (in particular, the power parameter, predictor weightings and subset of predictors), determine the assumed Heritability Model"

The Human Default Model is the recommended approach, with implementation scripts available in the examples below.

## Direct Method

Use the argument `--calc-kins-direct <outfile>`

**Required options:**
- `--bfile/--gen/--sp/--speed <datastem>` or `--bgen <datafile>` — specify genetic data files
- `--power <float>` — define predictor scaling

**Optional filtering:**
- `--keep <keepfile>` and/or `--remove <removefile>` — subset samples
- `--extract <extractfile>` and/or `--exclude <excludefile>` — subset predictors

By default, all predictors receive weight one. Provide custom weightings with `--weights <weightsfile>`.

## Indirect Method

### Step 1: Partition Predictors

Command: `--cut-kins <folder>`

**Required:**
- `--bfile/--gen/--sp/--speed <datastem>` or `--bgen <datafile>`
- Partitioning specification: `--partition-length <integer>`, `--by-chr YES`, or `--partition-number <integer>` with `--partition-prefix <prefix>`

### Step 2: Calculate Per-Partition Kinships

Command: `--calc-kins <folder>`

**Required:**
- Genetic data files
- `--partition <number>` — which partition to process
- `--power <float>` — scaling parameter

Use same filtering options as Step 1 if applicable.

### Step 3: Merge Matrices

Command: `--join-kins <folder>`

No additional options needed. Final output: `<folder>/kinships.all`

## Alternative Heritability Models

**Uniform Model:**
```
./ldak.out --calc-kins-direct UNI --bfile human --power -1
```

**LDAK Model:**
```
./ldak.out --calc-kins-direct LDAK --bfile human --weights <weightsfile> --power -.25
```

**LDAK-Thin Model:**
```
./ldak.out --thin thin --bfile human --window-prune .98 --window-kb 100
awk < thin.in '{print $1, 1}' > weights.thin
./ldak.out --calc-kins-direct LDAK-Thin --bfile human --weights weights.thin --power -.25
```

## Advanced Options

For PCGC regression, use external mean estimates with `--predictor-means <meansfile>`, which contains predictor name and average allele counts.
