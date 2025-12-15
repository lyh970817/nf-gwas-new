# Thin Predictors

## Overview

There are two main reasons to thin predictors. The first applies when constructing kinship matrices to assess population structure or relatedness. The second is when implementing the LDAK-Thin Model.

For quality control purposes, strong thinning is recommended to obtain predictors in approximate linkage equilibrium with no predictors within 1cM having squared correlation above 0.05. This focuses on genome-wide correlations rather than local correlations caused by linkage disequilibrium.

For the LDAK-Thin Model, light thinning ensures no duplicate predictors remain—specifically, no predictors within 100kb with squared correlation above 0.98.

## Important Note

For thinning only significant predictors from association testing results, use [Clumping](https://dougspeed.com/clumping/) instead.

Always review screen output, which suggests arguments and estimates memory usage.

---

## Main Arguments

The primary argument is `--thin <output>`.

Required options:
- `--bfile/--gen/--sp/--speed <datastem>` or `--bgen <datafile>` — genetic data files
- `--window-prune <float>` — correlation squared threshold
- `--window-cm <float>`, `--window-kb <float>`, or `--window-length <integer>` — window size

By default, LDAK removes one predictor randomly from highly-correlated pairs. Use `--pvalues <pvalues>` to exclude the less significant predictor instead.

Output files:
- `<output>.in` — retained predictors
- `<output>.out` — discarded predictors

---

## Recommendations

**For linkage equilibrium:** Use `--window-prune 0.05` and `--window-cm 1`. Aim for 50,000–100,000 SNPs when analyzing human SNP data.

**For LDAK-Thin Model:** Use `--window-prune 0.98` and `--window-kb 100`.

---

## Examples

Using binary PLINK files (human.bed, human.bim, human.fam):

**Linkage equilibrium thinning:**
```
../ldak.out --thin le --bfile human --window-prune 0.05 --window-cm 1
```

**Duplicate predictor thinning:**
```
../ldak.out --thin thin --bfile human --window-prune 0.98 --window-kb 100
```

Results save to `le.in` and `thin.in` respectively.
