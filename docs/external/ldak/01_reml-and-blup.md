# REML / HE / PCGC

## Overview

This section focuses on heritability analyses designed for individual-level data from unrelated samples. For GWAS summary statistics, users should use [SumHer](http://dougspeed.com/sumher/), while related samples should use [TetraHer or QuantHer](https://dougspeed.com/tetraher/).

## Key Considerations

**Point 1 - Quality Control:** "Most analyses require careful quality control. For example, estimates of SNP heritability can be very sensitive to population structure, family relatedness and genotyping errors." Begin with the [Quality Control](http://dougspeed.com/quality-control/) guidelines.

**Point 2 - Sample Size Requirements:** "Most analyses require a large number of unrelated samples. For example, to reliably estimate SNP heritability (standard deviation less than 5%), you generally need at least 7,000 unrelated samples."

**Point 3 - Data Flexibility:** Heritability analyses work with non-SNP data, including methylation data for estimating methylation heritability, though quality control and sample size requirements remain critical.

## Analysis Workflow

1. **Calculate Kinships** - [Calculate Kinships](http://dougspeed.com/calculate-kinships/) based on your chosen [Heritability Model](http://dougspeed.com/heritability-model/)

2. **Estimate Heritability** - Use one of three methods:
   - [REML](http://dougspeed.com/reml-analysis/) - restricted maximum likelihood
   - [HE Regression](http://dougspeed.com/haseman-elston-regression/) - Haseman Elston
   - [PCGC Regression](http://dougspeed.com/pcgc-regression/) - phenotype-correlation, genotype-correlation

## Method Recommendations

**REML** produces the most precise estimates and enables [BLUP](http://dougspeed.com/blup-estimates/) effect size estimation.

For larger datasets (30,000+ samples), consider **HE regression** for quantitative traits or **PCGC regression** for binary traits due to reduced computational burden and fewer distributional assumptions.

---

**Site:** [DougSpeed.com](https://dougspeed.com/) | Powered by WordPress
