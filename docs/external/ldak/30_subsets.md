# Sample Subsets

## Overview

Sample subsets are used to specify which samples belong to different cohorts. Originally designed to prevent genotyping errors when calculating [LDAK Weightings](http://dougspeed.com/get-weightings/), they can now also be applied when estimating heritability using [Haseman-Elston](http://dougspeed.com/haseman-elston-regression/) or [PCGC Regression](http://dougspeed.com/pcgc-regression/) methods. When sample subsets are provided, LDAK estimates heritability using only same-cohort sample pairs and only cross-cohort sample pairs.

## Usage

To provide sample subsets, use:
- `--subset-number <number>` to specify the number of subsets
- `--subset-prefix <subprefix>` to specify the prefix for sample lists

## Example Commands

**For calculating weightings with sample subsets:**

```bash
./ldak.out --cut-weights sections2 --bfile human
./ldak.out --calc-weights-all sections2 --bfile human --subset-number 2 --subset-prefix ind
```

**For Haseman-Elston regression with sample subsets:**

```bash
./ldak.out --he he4 --pheno quant.pheno --grm HumDef --subset-prefix ind --subset-number 2
```

**For PCGC regression with sample subsets:**

```bash
./ldak.out --pcgc pcgc4 --pheno binary.pheno --grm HumDef --prevalence .01 --subset-prefix ind --subset-number 2
```

## Explanation

Quality control is particularly critical in heritability analysis. The approach protects against widespread spurious associations that can accumulate across many SNPs. When case-control samples undergo separate genotyping, errors tend to correlate with outcomes, creating spurious associations.

The solution uses sample subsets to identify which sample batches were genotyped together. When calculating weightings, LDAK computes SNP correlations for each batch separately, then uses the maximum observed value. This preserves correct LD patterns even when individual batches show poor genotyping for specific SNPs.

Although this introduces an approximation, simulations show minimal impact. Regardless, strict quality control remains essential to minimize initial genotyping errors.
