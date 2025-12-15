# Filter Relatedness

## Overview

Heritability analysis requires samples to be "unrelated" (at most distantly related, with no pair closer than second cousins). This prevents inflated heritability estimates that would result from long-range linkage disequilibrium in related samples. The filtering process can obtain either unrelated or related sample subsets.

## Main Command

The primary argument is `--filter <outfile>`.

## Required Option

- `--grm <kinfile>` — provides a kinship matrix

## Filtering Options

By default, LDAK removes samples until no pair has kinship greater than the smallest observed value. Alternative approaches include:

- `--max-rel <float>` — specify a relatedness threshold (e.g., `--max-rel 0.05`)
- `--min-rel <float>` — retain only samples with relatedness above the threshold with at least one other sample (returns related samples)

## Additional Parameters

- `--keep <keepfile>` and/or `--remove <removefile>` — restrict to sample subsets
- `--pheno <phenofile>` — prioritize samples with non-missing phenotypes when choosing which related samples to keep

## Output Files

- Filtering for unrelatedness: `<outfile>.keep` and `<outfile>.lose`
- Filtering for relatedness: `<outfile>.related`

## Example

Using the LDAK-Thin kinship matrix:

```
./ldak.out --filter LDAK-Thin --grm LDAK-Thin
```

This retains 398 unrelated samples (kinship > 0.17) and removes 26 samples.

For related samples:

```
./ldak.out --filter LDAK-Thin --grm LDAK-Thin --min-rel .2
```

This identifies 25 samples with pairwise relatedness ≥ 0.2.
