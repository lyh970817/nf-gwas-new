# LDAK-KVIK Documentation

> Source: https://www.ldak-kvik.com/
> Downloaded: 2025-12-16

LDAK-KVIK is a fast mixed-model association analysis tool for genome-wide association studies (GWAS), part of the LDAK software suite.

## Documentation Structure

### Getting Started
- [Downloads](downloads.md) - Installation methods
- [Data Format](input.md) - Input file specifications
- [Example Code](example.md) - Quick start examples

### Core Documentation
- [LDAK-KVIK Steps](steps.md) - Three-step analysis process
- [LDAK-KVIK Options](options.md) - Command-line parameters
- [LDAK-KVIK Output](output.md) - Output file formats

### Advanced Topics
- [Recommendations](recommendations.md) - Best practices for different scenarios
- [Technical Details](technical.md) - Algorithm and methodology
- [Performance](performance.md) - Benchmarks and comparisons

### UK Biobank RAP
- [Data Preparation](ukbrap/preparation.md) - Preparing UKB data
- [Running LDAK-KVIK](ukbrap/running.md) - Executing on RAP
- [Recommendations](ukbrap/recommendations.md) - RAP-specific guidance

## Quick Overview

LDAK-KVIK executes in three sequential steps:

1. **Step 1**: Computes Leave-One-Chromosome-Out (LOCO) polygenic risk scores using Elastic Net regression
2. **Step 2**: Performs single-SNP association analysis
3. **Step 3**: Conducts gene-based association testing (optional)

## Key Features

- **Speed**: Faster than REGENIE for all sample sizes
- **Memory**: Lower memory usage for large cohorts (50k+ individuals)
- **Power**: Comparable to BOLT-LMM, outperforms fastGWA
- **Scalability**: Feasible for datasets with over one million individuals

## External Links

- Main LDAK website: https://www.ldak.org
- GitHub repository: https://github.com/dougspeed/LDAK
