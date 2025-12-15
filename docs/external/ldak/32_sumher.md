# SumHer | DougSpeed.com

## Overview

SumHer is a tool for analyzing summary statistics with four primary objectives:

1. Estimate the SNP Heritability of a trait
2. Estimate Heritability Enrichments
3. Estimate Genetic Correlations
4. Estimate the selection-related parameter alpha

## Key Information

The tool follows a two-step process. First, obtain a tagging file that provides expected heritability tagged by each predictor under the chosen Heritability Model. You can either calculate taggings yourself using a reference panel, or use pre-computed taggings calculated from UK Biobank data.

The second step involves regressing properly-formatted summary statistics onto the tagging file.

**Important Note:** SumHer currently supports only common predictors (MAF>0.01 or MAF>0.005). Rare predictor accommodation is under development.

### Historical Note

An earlier function estimated confounding bias in association studies, but this is no longer recommended. The developers now advise analyzing summary statistics only when confident they derive from careful quality control studies that excluded poorly-genotyped SNPs and minimized confounding from relatedness or population structure.
