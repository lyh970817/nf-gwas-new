# LDAK-KVIK Technical Details

LDAK-KVIK is a fast mixed-model association analysis tool for genome-wide association studies (GWAS). The method comprises two or three analytical steps depending on whether gene-based analysis is performed.

## Algorithm Steps

### Step 1: Construct LOCO PRS and Estimate λ

This foundational step involves five operations:

#### Operation 1a - Test for Population Structure

The algorithm randomly selects 512 SNPs across the genome to compute average squared correlations between SNP pairs on different chromosomes. LDAK-KVIK determines there is strong structure if both:
- ρ̄² is significantly greater than 0
- nρ̄² > 0.1

#### Operation 1b - Estimate Power and Heritability Parameters

The method employs randomized Haseman-Elston Regression, testing five alpha values: -1, -0.75, -0.5, -0.25, and 0.

Per-SNP heritabilities are calculated using:
```
wⱼ = [fⱼ(1-fⱼ)]^(1+α̂)
```

Where fⱼ is the allele frequency and α̂ is the estimated power parameter.

#### Operation 1c - Refine Heritability via Monte Carlo REML

The REML estimate iteratively refines the heritability calculations using the phenotype and covariance matrix, beginning with Haseman-Elston estimates.

#### Operation 1d - Elastic Net Cross-Validation

The algorithm tests nine hyperparameter combinations:
- (p,F) = (0.5,0.5), (0.5,0.3), (0.5,0.1)
- (p,F) = (0.1,0.5), (0.1,0.3), (0.1,0.1)
- (p,F) = (0.01,0.5), (0.01,0.3), (0.01,0.1)
- (p,F) = (0,1)

Selection uses 10-fold cross-validation on 90% of individuals.

#### Operation 1e - LOCO PRS Construction

Leave-one-chromosome-out (LOCO) PRS are constructed for each chromosome using optimal elastic net parameters. Structure adjustment involves ridge regression comparison when population structure is detected.

### Step 2: Single-SNP Association Analysis

#### Operation 2a - Calculate Uncalibrated Test Statistics

Standard ordinary least-squares regression tests each SNP's association with the phenotype, accounting for the LOCO PRS as an offset.

#### Operation 2b - Scale Test Statistics

Three reported values per SNP include:
- Effect size estimate
- Variance estimate
- Scaled χ²(1) test statistic

All are adjusted by the λ scaling factor.

### Step 3: Gene-Based Association Analysis

#### Operation 3a - LDAK-GBAT Execution

Gene-based analysis uses single-SNP summary statistics with LDAK-GBAT, a separate tool performing restricted maximum likelihood (REML) testing on genomic relatedness matrices constructed from gene-specific SNPs.

## Key Methodological Details

### Residual Phenotypes and Genotypes

All regressions employ residual-adjusted data:
```
Y_residual = HY^T
X_residual = HX^T
```

Where H = I − Z(Z^TZ)^−1Z^T, then scaling Y (columns of X) to have variance one.

### Elastic Net Prior Distribution

The SNP effect size prior is specified as:
```
γⱼ ~ pDE(...) + (1-p)N(0, Fĥ²ⱼ/(1-p))
```

Where:
- p controls lasso contribution
- F controls ridge regression variance contribution

### Structure Adjustment

When population structure is detected, the algorithm:
1. Constructs separate PRS using ridge regression priors
2. Compares test statistics
3. Computes appropriate scaling corrections

## Computational Efficiency

It is not needed to use the full genotype data in LDAK-KVIK Step 1. Instead, we recommend using a subset of SNPs to compute LOCO PRS and estimate λ, which substantially reduces run time with minimal impact on statistical performance.

### Resource Requirements

- **Memory**: Approximately 10GB for full UK Biobank datasets
- **CPU**: Benefits from multi-threading, but gains plateau after 4-8 threads
- **Storage**: Input PLINK files + output summary statistics
