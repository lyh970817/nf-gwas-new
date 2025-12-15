# Simulate Data

## Overview

LDAK can generate genotypic and phenotypic data for simulation studies. This allows users to create phenotypes under various genetic architectures and test how different tools identify causal variants, construct prediction models, or estimate heritability.

> "Always read the screen output, which suggests arguments and estimates memory usage."

---

## Simulating Genotypes

**Main argument:** `--make-snps <outfile>`

### Required Options
- `--num-samples <integer>` — number of samples
- `--num-snps <integer>` — number of SNPs

### Default Behavior

LDAK generates SNPs assuming Hardy-Weinberg equilibrium and linkage equilibrium. By default:
- MAF ranges from 0.01 to 0.5
- 22 chromosomes included
- No missing values

### Customization Options
- `--maf-low <float>` and `--maf-high <float>` — adjust MAF range
- `--num-chr <integer>` — change chromosome count
- `--missing-rate <float>` — introduce missing values
- `--family-size <integer>` and `--relatedness <float>` — generate family-based data
- `--populations <integer>` — generate multiple population groups

**Output:** Binary PLINK format files (.bed, .bim, .fam)

---

## Simulating Phenotypes

**Main argument:** `--make-phenos <outfile>`

### Required Options
- `--bfile/--gen/--sp/--speed <datastem>` or `--bgen <datafile>` — genetic data files
- `--power <float>` — predictor scaling
- `--her <float>` — heritability for simulated phenotypes
- `--num-phenos <integer>` — number of phenotypes
- `--num-causals <integer>` — causal predictors per phenotype (use `ALL` for all predictors)

### Phenotype Construction

LDAK selects C causal SNPs randomly, then constructs scaled genotypes using: **Xj = (Sj - mj) [2fj(1-fj)]^(alpha/2)**, where:
- Sj = raw genotypes for the jth causal SNP
- mj = mean of Sj
- fj = MAF of Sj
- alpha = power parameter

Phenotypes are generated as: **Y = X₁b₁ + X₂b₂ + ... + XCbC + e**

where effect sizes (bj) follow a standard Gaussian distribution and environmental noise (e) is adjusted to achieve specified heritability.

### Advanced Options
- `--causals <causalsfile>` — specify causal predictors
- `--effects <effectsfile>` — specify effect sizes
- `--weights <weightsfile>` — provide predictor weightings
- `--covar <covarfile>` and `--covar-her <float>` — include covariate effects
- `--prevalence <float>` — generate binary phenotypes
- `--bivar <float>` — generate correlated phenotypes with genetic correlation
- `--bivar-env <float>` — correlate environmental noise terms

**Output files:**
- `.pheno` — simulated phenotypes
- `.effects` — causal predictor details
- `.breeding` — genetic contribution to each phenotype
- `.liab` — liabilities (if binary phenotypes generated)

---

## Examples

### Generate SNP Genotypes
```bash
./ldak.out --make-snps snps --num-samples 100 --num-snps 1000
```
Creates 100 samples with 1,000 SNPs in binary PLINK format.

### Generate Phenotypes (Uniform Model)
```bash
./ldak.out --make-phenos UNI --bfile snps --power -1 --her 0.5 --num-phenos 10 --num-causals 100
```

### Generate Phenotypes (Human Default Model)
```bash
./ldak.out --make-phenos HumDef --bfile snps --power -.25 --her 0.5 --num-phenos 10 --num-causals 100
```
