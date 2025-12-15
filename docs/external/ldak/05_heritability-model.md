# Heritability Model

## Overview

All heritability analyses require specifying a heritability model that describes how much each predictor is expected to influence the phenotype. The choice of model significantly impacts results, affecting SNP heritability estimates, heritability enrichments, and polygenic score accuracy.

## Historical Development

The **Uniform Model** (also called the GCTA Model) was the first approach, assuming all predictors explain equal heritability. Later, the **LDAK Model** was developed, where expected heritability depends on minor allele frequency (MAF) and local linkage disequilibrium (LD) levels.

## Recent Advances

In the 2020 *Nature Genetics* paper "Evaluating and improving heritability models using summary statistics," researchers compared 12 different models across complex traits:

- **LDAK-Thin Model**: Best-performing among simple models
- **BLD-LDAK Model**: Top performer overall, incorporating MAF, LD, and functional annotations

## Current Recommendations

The page recommends two primary models:

1. **Human Default Model**: Specifies the relationship between per-predictor heritabilities and MAF. Use for REML, Haseman Elston Regression, PCGC, LDAK-GBAT, SNP heritability, and genetic correlations.

2. **Alpha Model**: Estimates the MAF relationship from data. Use for LDAK-KVIK and MegaPRS.

Both models balance robustness with ease of use, though more sophisticated annotation-based models exist.

## Additional Resources

- [Technical Details](http://dougspeed.com/technical-details/): Implementation guidance
- [Comparing Models](https://dougspeed.com/compare-models/): Testing different approaches
