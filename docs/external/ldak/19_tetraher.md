# TetraHer and QuantHer

## Overview

TetraHer and QuantHer are tools designed for estimating heritability in related samples. TetraHer focuses on binary phenotypes (such as diseases) by calculating liability heritability, while QuantHer estimates heritability for quantitative traits. These methods require individual-level data from related individuals and differ from SNP heritability estimation approaches like REML or Haseman-Elston Regression, which are better suited for unrelated samples.

## TetraHer

### Main Argument
`--tetra-her <outfile>`

### Required Options

- **`--relatives <pairsfile>`**: Specifies pairs of related individuals. The file should contain 5-6 columns: columns 1-2 and 3-4 provide individual IDs for each pair member, column 5 specifies relatedness, and optional column 6 indicates environmental similarity. See the Relatives File documentation for format details and construction scripts.

- **`--pheno <phenofile>`**: Provides phenotypes in PLINK format. Samples lacking phenotypes are excluded. Use `--mpheno <integer>` to select a specific phenotype or `--mpheno ALL` to analyze all phenotypes.

### Optional Arguments

- **`--covar <covarfile>`** or **`--factors <factorfile>`**: Includes quantitative or categorical covariates as fixed effects; phenotypic variance from these is discounted during heritability calculation.

- **`--prevalence <prevalence>`**: Specifies population prevalence (otherwise assumes sample prevalence equals population prevalence).

- **`--constrain YES`**: Restricts heritability estimates to positive values (by default, estimates can be negative for unbiased results near zero).

### Output

The primary output file is `<outfile>.mle`, where:
- "Genetic" row reports estimated heritability (h2L)
- "Environmental" row reports common environment contribution (h2C)

## QuantHer

### Main Argument
`--quant-her <outfile>`

### Required Options

- **`--relatives <pairsfile>`**: Same format and requirements as TetraHer

- **`--pheno <phenofile>`**: Same format as TetraHer with identical phenotype selection options

### Optional Arguments

- **`--covar <covarfile>`**: Includes quantitative covariates as fixed effects

- **`--prevalence <float>`**: For binary phenotypes, specifies population prevalence and enables liability scale heritability reporting (though TetraHer is generally preferred for binary traits)

- **`--constrain YES`**: Same functionality as TetraHer

### Output

The primary output file is `<outfile>.mle`, where:
- "Genetic" row reports estimated heritability (h2O)
- "Environmental" row reports common environment contribution (h2C)

## Example Analyses

### TetraHer Examples

**Basic analysis:**
```
./ldak.out --tetra-her tetraher1 --relatives disease.relatives --pheno disease.pheno
```
Result: Estimated heritability = 0.54 (SD 0.05)

**Accounting for ascertainment:**
```
./ldak.out --tetra-her tetraher2 --relatives disease.relatives --pheno disease.pheno --prevalence 0.1
```
Result: Estimated heritability = 0.45 (SD 0.04)

**Including covariates:**
```
./ldak.out --tetra-her tetraher3 --relatives disease.relatives --pheno disease.pheno --prevalence 0.1 --covar disease.covar
```
Result: Estimated heritability = 0.56 (SD 0.05)

**Accounting for common environment:**
```
./ldak.out --tetra-her tetraher4 --relatives disease.enviro --pheno disease.pheno --prevalence 0.1 --covar disease.covar
```
Results: Estimated heritability = 0.32 (SD 0.18); common environment = 0.12 (SD 0.10)

### QuantHer Examples

**Basic analysis:**
```
ldak.out --quant-her quanther1 --relatives disease.relatives --pheno disease.pheno
```
Result: Estimated heritability = 0.29 (SD 0.03)

**Including covariates:**
```
./ldak.out --quant-her quanther2 --relatives disease.relatives --pheno disease.pheno --covar disease.covar
```
Result: Estimated heritability = 0.31 (SD 0.03)

**Accounting for common environment:**
```
./ldak.out --quant-her quanther3 --relatives disease.enviro --pheno disease.pheno --covar disease.covar
```
Results: Estimated heritability = 0.19 (SD 0.10); common environment = 0.07 (SD 0.05)

## Important Notes

Always review the screen output, which provides argument suggestions and memory usage estimates. The methods accept negative heritability estimates by default to ensure unbiased results near zero; use `--constrain YES` if positive-only estimates are preferred.
