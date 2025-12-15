# Pseudo Summaries

## Overview

Pseudo training and test summary statistics simulate what summary statistics would look like if a GWAS had used different sample subsets. For instance, with summary statistics from a 100,000-sample GWAS, you can generate pseudo statistics mimicking results from 90,000 and 10,000 sample analyses respectively.

These pseudo statistics help determine suitable model parameters when running MegaPRS. However, when using MegaPRS with the `--mega-prs` command, LDAK now generates pseudo summary statistics internally, making explicit generation unnecessary.

## Requirements

A well-matched reference panel with at least 2,000 samples is required. For smaller panels, scripts exist to construct one from 1000 Genomes Project data (see Reference Panel section).

Always review screen output for suggested arguments and memory usage estimates.

## Main Command and Options

**Primary argument:** `--pseudo-summaries <outfile>`

**Required options:**
- `--bfile/--gen/--sp/--speed <datastem>` or `--bgen <datafile>` — specify genetic data files
- `--summary <sumsfile>` — specify summary statistics file
- `--training-proportion <float>` — fraction of samples as training (0.9 recommended)

**Optional filtering:**
- `--keep <keepfile>` and/or `--remove <removefile>` — sample subsets
- `--extract <extractfile>` and/or `--exclude <excludefile>` — predictor subsets

**Handling ambiguous alleles:**

By default, LDAK excludes predictors with A/T or C/G alleles to prevent strand errors. Use `--allow-ambiguous YES` if confident in alignment.

**Output files:** `<outfile>.train.summaries` and `<outfile>.test.summaries`

## Example

Using test dataset files (human.bed, human.bim, human.fam) and quant.pheno:

First, create summary statistics:
```
./ldak.out --linear quant --bfile human --pheno quant.pheno
```

Then generate pseudo summaries:
```
./ldak.out --pseudo-summaries quant --bfile human --summary quant.summaries \
--training-proportion .9 --allow-ambiguous YES
```

Results save to quant.train.summaries and quant.test.summaries.
