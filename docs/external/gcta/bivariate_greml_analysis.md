# Bivariate GREML Analysis in GCTA

**Source**: https://yanglab.westlake.edu.cn/software/gcta/#BivariateGREMLanalysis

---

## Overview

Bivariate GREML extends the standard GREML method to estimate genetic correlation between two traits or diseases using genome-wide SNP data. This approach enables researchers to determine whether traits share common genetic influences.

## Key Features

### Genetic Correlation Estimation

The bivariate method allows simultaneous analysis of two traits measured across individuals. The software estimates the proportion of phenotypic variance explained by SNPs for each trait separately, plus the genetic correlation between them.

### Flexible Study Designs

One notable application involves analyzing two traits in independent samples. According to the documentation: "this analysis also applies to a single trait measured in two samples. Then the analysis is to estimate genetic correlation between two samples for the same trait."

## Methodology

The analysis requires:
- A combined genetic relationship matrix (GRM) from all individuals across both samples
- A phenotype file containing both traits, with missing values ("NA") for individuals who lack one measurement

Example phenotype structure shows individuals from sample #1 with trait1 data and individuals from sample #2 with trait2 data, using "NA" for unmeasured traits.

## Output Interpretation

Results include separate variance estimates (V(1), V(2)) for each trait's genetic component, along with their correlation. The output file format presents genetic variance estimates, residual variance, phenotypic variance, and the crucial genetic correlation parameter.

## Citation

Lee et al. (2012) developed this approach: "Estimation of pleiotropy between complex diseases using SNP-derived genomic relationships and restricted maximum likelihood" (*Bioinformatics*, 28(19): 2540-2542).

---

## Related Resources

- [GCTA Official Website](https://yanglab.westlake.edu.cn/software/gcta/)
- Main GREML Analysis Documentation
