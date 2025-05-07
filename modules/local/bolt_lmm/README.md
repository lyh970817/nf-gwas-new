# BOLT-LMM Module

This module implements the BOLT-LMM REML (Restricted Maximum Likelihood) algorithm for variance components analysis as described in the [BOLT-LMM documentation](https://alkesgroup.broadinstitute.org/BOLT-LMM/BOLT-LMM_manual.html).

## Overview

BOLT-REML is used for estimating heritability explained by genotyped SNPs and genetic correlations among multiple traits measured on the same set of individuals. It applies a Monte Carlo algorithm that is much faster than eigendecomposition-based methods for variance components analysis at large sample sizes.

## Processes

### RUN_BOLT_REML

This process runs the BOLT-LMM REML analysis on the provided genotype data.

#### Inputs:
- Genotype data in PLINK1 format (bed/bim/fam) from IMPUTED_TO_PLINK process
- Phenotype file
- Quantitative covariates file (optional)
- Categorical covariates file (optional)

#### Outputs:
- REML results files (*.reml*)
- Log file (*.log)

## Parameters

The following parameters can be set in the Nextflow configuration:

- `params.pubDir`: Output directory for published results
- `params.phenotype_column`: Column name in the phenotype file to use for analysis
- `params.covariates_columns`: Comma-separated list of all covariate column names
- `params.covariates_cat_columns`: Comma-separated list of categorical covariate column names
- `params.modelSnps`: File containing SNPs to include in the model (optional)
- `params.ldscoresFile`: File containing LD scores for BOLT-LMM (optional)
- `params.geneticMapFile`: File containing genetic map for BOLT-LMM (optional)

## Implementation Notes

- The module uses the `Channel.of([])` pattern for handling optional inputs, as recommended in the nf-gwas pipeline.
- Empty covariate files are handled by using a simple truthiness check (e.g., `qcovariates_file ? param : ''`), following the pattern used in the LDAK module.
- Multiple covariates are handled by generating separate `--qCovarCol` and `--covarCol` flags for each covariate, as required by BOLT-LMM.
- Quantitative covariates are determined by subtracting categorical covariates from all covariates.

## Usage

The BOLT-LMM module is included in the main nf-gwas workflow and can be run as part of the full pipeline.

### Example:

```nextflow
nextflow run main.nf --phenotypes_filename phenotypes.txt --covariates_filename covariates.txt --genotypes_association "path/to/genotypes/*.vcf.gz" --ldscoresFile "path/to/LDSCORE.1000G_EUR.tab.gz" --geneticMapFile "path/to/genetic_map_hg19.txt.gz"
```

## References

Loh, P.-R. et al. Contrasting genetic architectures of schizophrenia and other complex diseases using fast variance components analysis. Nature Genetics 47, 1385–1392 (2015).
