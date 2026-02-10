# REGENIE Workflow

[Back to main README](../../README.md)

REGENIE is a two-step whole genome regression method for genome-wide association studies (GWAS) in biobank-scale datasets. It efficiently handles hundreds of thousands of samples while controlling for population structure and relatedness.

## Table of Contents

- [Overview](#overview)
- [When to Use REGENIE](#when-to-use-regenie)
- [Quick Start](#quick-start)
- [Input Requirements](#input-requirements)
- [Parameters](#parameters)
- [Usage Examples](#usage-examples)
- [Output Files](#output-files)
- [Advanced Features](#advanced-features)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

---

## Overview

REGENIE uses a two-step approach:

1. **Step 1 (Prediction)**: Builds a whole genome regression model using array genotypes or a subset of high-quality SNPs
2. **Step 2 (Association)**: Tests each variant for association using leave-one-chromosome-out (LOCO) predictions from Step 1

### Key Advantages

- **Scalable**: Handles 100k+ samples efficiently
- **Flexible**: Supports quantitative and binary traits
- **Robust**: Firth correction for rare variant association

---

## When to Use REGENIE

| Scenario | Recommendation |
|----------|----------------|
| Large biobank (N > 50k) | **Recommended** |
| Case-control imbalance | **Recommended** (Firth correction) |
| Small samples (N < 5k) | Consider GCTA GREML |
| Summary statistics only | Use LDAK SumHer/SumCors instead |

---

## Quick Start

```bash
# Basic GWAS with REGENIE
nextflow run main.nf \
    --project my_gwas \
    --run_association_analysis true \
    --genotypes_association_vcf "data/chr*.vcf.gz" \
    --genotypes_prediction "data/array.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    --regenie_test additive \
    -profile singularity
```

---

## Input Requirements

### Required Files

| File | Description | Format |
|------|-------------|--------|
| **Genotypes (Association)** | Imputed genotypes for testing | VCF (`*.vcf.gz`) |
| **Genotypes (Prediction)** | Array genotypes for Step 1 | PLINK (`*.bed,*.bim,*.fam`) |
| **Phenotypes** | Trait values (one file per trait) | Tab-separated text |

### Optional Files

| File | Description | Format |
|------|-------------|--------|
| **Covariates** | Adjustment variables | Tab-separated text |

### File Format Examples

**Phenotype Files (one per trait)**:
```
phenotypes/
├── height.txt
└── bmi.txt
```

Each file:
```
FID    IID    height
1001   1001   175.5
1002   1002   162.3
1003   1003   NA
```
- Missing values: `NA` or `-9`
- Binary traits: `0`/`1` or `1`/`2` coding

**Covariate File**:
```
FID    IID    age    sex    PC1       PC2       PC3
1001   1001   45     1      0.0123   -0.0089    0.0034
1002   1002   52     2      0.0031    0.0156   -0.0021
```

---

## Parameters

### Essential Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--genotypes_association_vcf` | VCF files for association testing | Required |
| `--genotypes_prediction` | PLINK files for Step 1 | Required (unless skipping) |
| `--phenotypes_dir` | Directory of phenotype files (one trait per file) | Required |
| `--regenie_test` | Test type: `additive`, `recessive`, `dominant` | `additive` |

### Step 1 Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--regenie_skip_predictions` | Skip Step 1 (use null model) | `false` |
| `--regenie_bsize_step1` | Block size for Step 1 | `1000` |
| `--regenie_force_step1` | Allow >1M variants in Step 1 | `false` |
| `--regenie_low_mem` | Low memory mode | `true` |
| `--genotypes_prediction_chunks` | Split Step 1 into chunks | `0` (no chunking) |

### Step 2 Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--regenie_bsize_step2` | Block size for Step 2 | `400` |
| `--regenie_firth` | Use Firth correction | `true` |
| `--regenie_firth_approx` | Approximate Firth (faster) | `true` |

### Binary Traits

Binary traits are auto-detected per phenotype file (values like 0/1 or 1/2).

---

## Usage Examples

### Single-Variant Association (Quantitative Trait)

```bash
nextflow run main.nf \
    --project height_gwas \
    --run_association_analysis true \
    --genotypes_association_vcf "imputed/chr*.vcf.gz" \
    --genotypes_prediction "array/genotypes.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    --covariates_filename covariates.txt \
    --covariates_columns age,sex,PC1,PC2,PC3,PC4,PC5 \
    --regenie_test additive \
    -profile slurm,singularity
```

### Case-Control Study (Binary Trait)

```bash
nextflow run main.nf \
    --project disease_gwas \
    --run_association_analysis true \
    --genotypes_association_vcf "imputed/chr*.vcf.gz" \
    --genotypes_prediction "array/genotypes.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    --regenie_firth true \
    --regenie_firth_approx true \
    -profile slurm,singularity
```

### Multiple Phenotypes

```bash
nextflow run main.nf \
    --project multi_trait \
    --run_association_analysis true \
    --genotypes_association_vcf "imputed/chr*.vcf.gz" \
    --genotypes_prediction "array/genotypes.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

### Recessive Model

```bash
nextflow run main.nf \
    --project recessive_gwas \
    --run_association_analysis true \
    --genotypes_association_vcf "imputed/chr*.vcf.gz" \
    --genotypes_prediction "array/genotypes.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    --regenie_test recessive \
    -profile slurm,singularity
```

### Skip Predictions (Null Model)

When you don't have array genotypes:

```bash
nextflow run main.nf \
    --project gwas_no_step1 \
    --run_association_analysis true \
    --genotypes_association_vcf "imputed/chr*.vcf.gz" \
    --phenotypes_dir phenotypes/ \
    --regenie_skip_predictions true \
    -profile singularity
```

---

## Output Files

### Directory Structure

```
output/project_name/
├── regenie/
│   ├── step1/
│   │   ├── regenie_step1_out_pred.list      # Prediction file list
│   │   ├── regenie_step1_out_*.loco.gz      # LOCO predictions
│   │   └── regenie_step1_out.log            # Step 1 log
│   │
│   └── step2/
│       ├── regenie_step2_chr1_height.regenie.gz   # Chr 1 results
│       ├── regenie_step2_chr2_height.regenie.gz   # Chr 2 results
│       └── ...
```

### Result File Format

**Association Results** (`*.regenie.gz`):

| Column | Description |
|--------|-------------|
| CHROM | Chromosome |
| GENPOS | Genomic position |
| ID | Variant ID |
| ALLELE0 | Reference allele |
| ALLELE1 | Effect allele |
| A1FREQ | Effect allele frequency |
| N | Sample size |
| BETA | Effect size estimate |
| SE | Standard error |
| CHISQ | Chi-square statistic |
| LOG10P | -log10(p-value) |
| EXTRA | Additional info |

---

## Advanced Features

Note: REGENIE gene-based association is no longer available in this pipeline.

### Chunked Step 1 (Memory-Limited Systems)

Split Step 1 across multiple jobs:

```bash
nextflow run main.nf \
    --project chunked_gwas \
    --run_association_analysis true \
    --genotypes_association_vcf "imputed/chr*.vcf.gz" \
    --genotypes_prediction "array/genotypes.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    --genotypes_prediction_chunks 10 \
    -profile slurm,singularity
```

---

## Performance Tips

### Memory Optimization

| Scenario | Recommendation |
|----------|----------------|
| Step 1 runs out of memory | Enable `--regenie_low_mem true` |
| Still not enough memory | Use `--genotypes_prediction_chunks 10` |
| Large number of variants | Consider pruning prediction genotypes |

### Speed Optimization

| Scenario | Recommendation |
|----------|----------------|
| Many phenotypes | Provide all files in `--phenotypes_dir` (pipeline runs per phenotype) |
| Large datasets | Use HPC cluster with `--profile slurm,singularity` |
| Binary traits | Use `--regenie_firth_approx true` (default) |

### Recommended QC Before Running

1. **Filter prediction genotypes**:
   - MAF > 1%
   - Genotyping rate > 90%
   - HWE p > 1e-15
   - LD pruning (r² < 0.9)

2. **Verify sample overlap** between genotype and phenotype files

3. **Check for related individuals** (REGENIE handles relatedness, but extreme cases may need filtering)

---

## Troubleshooting

### Step 1 Fails

**Error**: "Not enough variants after filtering"
```
Solution: Ensure prediction genotypes have >1000 variants after QC.
Check MAF and missingness filters.
```

**Error**: "Memory allocation failed"
```
Solution: Enable --regenie_low_mem true or use --genotypes_prediction_chunks
```

### Step 2 Produces No Results

**Error**: "No variants pass filtering"
```
Solution:
- Verify VCF files contain variants
```

### Binary Trait Issues

**Error**: "Case-control imbalance detected"
```
Solution: This is a warning, not an error.
REGENIE will automatically use Firth correction.
Ensure --regenie_firth true (default).
```

### Sample ID Mismatch

**Error**: "Samples in phenotype file not found in genotype file"
```
Solution:
- Ensure FID and IID columns match exactly
- Check for whitespace issues
- Verify phenotype file uses same ID format as PLINK files
```

---

## References

- Mbatchou et al. (2021). Computationally efficient whole-genome regression for quantitative and binary traits. *Nature Genetics*. https://doi.org/10.1038/s41588-021-00870-7
- [REGENIE Documentation](https://rgcgithub.github.io/regenie/)
- [REGENIE GitHub](https://github.com/rgcgithub/regenie)

---

## Related Workflows

- [LDAK-KVIK](../ldak/README.md) - Faster alternative for GWAS
- [GCTA FastGWA](../gcta/README.md) - Alternative mixed model approach
- [GCTA GREML](../gcta/README.md) - Heritability estimation from GWAS data
