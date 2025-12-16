# BOLT-LMM Workflow

[Back to main README](../../README.md)

BOLT-LMM (Bayesian Open-source Linkage-based Test for Linear Mixed Models) provides fast mixed model analysis for heritability estimation and association testing. It uses randomized algorithms to achieve computational efficiency while maintaining statistical accuracy.

## Table of Contents

- [Overview](#overview)
- [When to Use BOLT-LMM](#when-to-use-bolt-lmm)
- [Quick Start](#quick-start)
- [Input Requirements](#input-requirements)
- [Parameters](#parameters)
- [Usage Examples](#usage-examples)
- [Output Files](#output-files)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

---

## Overview

BOLT-LMM implements:

| Feature | Description |
|---------|-------------|
| **REML Estimation** | Variance component estimation |
| **Mixed Model Association** | GWAS with correction for structure/relatedness |
| **Bayesian Priors** | Mixture-of-normals prior for effect sizes |

### Key Advantages

- **Fast**: O(N) complexity via randomized algorithms
- **Scalable**: Handles 100k+ samples efficiently
- **Accurate**: Well-calibrated test statistics
- **Versatile**: Works with both quantitative and binary traits

### Current Implementation

This pipeline currently implements BOLT-LMM REML for heritability estimation. Full association testing workflows can be added following the same pattern.

---

## When to Use BOLT-LMM

| Scenario | Recommendation |
|----------|----------------|
| Fast heritability (N > 5k) | **Recommended** |
| Large biobank GWAS | Consider (or REGENIE/LDAK-KVIK) |
| Small samples (N < 5k) | Use GCTA GREML instead |
| Gene-based tests | Use REGENIE instead |
| Binary traits (case-control) | Consider LDAK PCGC for liability scale |

---

## Quick Start

```bash
nextflow run main.nf \
    --project h2_bolt \
    --run_heritability_estimation true \
    --heritability_method bolt_lmm \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height \
    -profile singularity
```

---

## Input Requirements

### Required Files

| File | Description | Format |
|------|-------------|--------|
| **Genotypes** | SNP data | PLINK1 (bed/bim/fam) only |
| **Phenotypes** | Trait values | Tab-separated text |

### Optional Files

| File | Description | Format |
|------|-------------|--------|
| **Covariates** | Adjustment variables | Tab-separated text |

### File Format Requirements

**Important**: BOLT-LMM requires PLINK1 format (bed/bim/fam). The pipeline will automatically convert from VCF if needed.

**Phenotype File**:
```
FID    IID    height    bmi
1001   1001   175.5     24.3
1002   1002   162.3     22.1
```

**Covariate File**:
```
FID    IID    age    sex    PC1       PC2
1001   1001   45     1      0.0123   -0.0089
1002   1002   52     2      0.0031    0.0156
```

---

## Parameters

### Essential Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--genotypes_association_plink1` | PLINK1 files | Required |
| `--phenotypes_filename` | Phenotype file | Required |
| `--phenotypes_columns` | Phenotype column names | Required |

### Covariate Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--covariates_filename` | Covariate file | Optional |
| `--covariates_columns` | All covariate names | Optional |
| `--covariates_cat_columns` | Categorical covariates | Optional |

BOLT-LMM distinguishes between:
- **Categorical covariates** (`--covarCol`): Treated as factors
- **Quantitative covariates** (`--qCovarCol`): Treated as continuous

---

## Usage Examples

### Basic REML Heritability

```bash
nextflow run main.nf \
    --project h2_bolt \
    --run_heritability_estimation true \
    --heritability_method bolt_lmm \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height \
    -profile singularity
```

### With Covariates

```bash
nextflow run main.nf \
    --project h2_bolt_cov \
    --run_heritability_estimation true \
    --heritability_method bolt_lmm \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height \
    --covariates_filename covariates.txt \
    --covariates_columns age,sex,PC1,PC2,PC3,PC4,PC5 \
    --covariates_cat_columns sex \
    -profile singularity
```

### Multiple Phenotypes

```bash
nextflow run main.nf \
    --project h2_multi \
    --run_heritability_estimation true \
    --heritability_method bolt_lmm \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height,bmi,waist_circumference \
    -profile slurm,singularity
```

### Binary Trait

```bash
nextflow run main.nf \
    --project h2_binary \
    --run_heritability_estimation true \
    --heritability_method bolt_lmm \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns disease_status \
    --phenotypes_binary_trait true \
    -profile singularity
```

Note: For binary traits, BOLT-LMM estimates heritability on the observed scale. For liability-scale estimates, consider using LDAK PCGC.

---

## Output Files

### Directory Structure

```
output/project_name/
└── bolt_lmm/
    └── phenotype.bolt.reml.log    # REML results
```

### Log File Contents

The log file contains:

```
                            BOLT-LMM v2.4 Log

Command line:
bolt --reml ...

Data summary:
  Samples: 50,000
  SNPs after filtering: 500,000
  Phenotype: height

Variance component estimation:
  Genetic variance (Vg): 0.4523 (SE 0.0234)
  Environmental variance (Ve): 0.5477 (SE 0.0234)
  Total variance (Vp): 1.0000

  Heritability (h2 = Vg/Vp): 0.4523 (SE 0.0234)

Log-likelihood: -12345.67
Iterations: 15
Converged: Yes
```

### Extracting Results

```bash
# Extract heritability estimate
grep "Heritability" output/project/bolt_lmm/*.log

# Or use a simple script
grep -E "h2|Heritability|Vg|Ve" output/project/bolt_lmm/*.log
```

---

## Performance Tips

### Memory Requirements

| Sample Size | Recommended Memory |
|-------------|-------------------|
| N = 10,000 | 16 GB |
| N = 50,000 | 64 GB |
| N = 100,000 | 128 GB |
| N = 500,000 | 256 GB+ |

### Speed Considerations

1. **BOLT-LMM is O(N)** in sample size (vs O(N²) for GCTA)
2. **More efficient for N > 5,000** compared to GCTA
3. **Less efficient for very small N** (< 2,000)

### Best Practices

1. **QC genotypes first**: MAF > 1%, call rate > 95%
2. **Include PCs**: At least PC1-PC10 as quantitative covariates
3. **Check convergence**: Verify "Converged: Yes" in log
4. **Memory allocation**: Request sufficient memory on HPC

---

## Troubleshooting

### Memory Errors

**Error**: "Not enough memory" or "Memory allocation failed"
```
Solution:
- Increase memory allocation (job request)
- BOLT-LMM loads all SNPs into memory
- Estimate: ~2-4 GB per 100k SNPs
```

### Convergence Issues

**Error**: "REML did not converge"
```
Possible causes:
1. Small sample size (N < 1000)
2. Heritability near boundary (0 or 1)
3. Issues with phenotype distribution

Solutions:
- Verify phenotype is properly scaled
- Check for outliers in phenotype
- Try simpler model (fewer covariates)
```

### Sample ID Mismatch

**Error**: "Sample IDs do not match"
```
Solution:
- Ensure FID and IID match exactly between files
- Check for whitespace or encoding issues
- PLINK FAM file IDs must match phenotype file
```

### Binary Trait Detection

**Warning**: "Binary phenotype detected"
```
BOLT-LMM will automatically:
- Detect 0/1 or 1/2 coded phenotypes
- Apply appropriate liability transformation

For precise liability-scale h², consider LDAK PCGC.
```

### Related Individuals

**Warning**: "Sample pairs with high relatedness detected"
```
BOLT-LMM can handle moderate relatedness but:
- Consider removing close relatives (GRM > 0.25)
- Very high relatedness may inflate estimates
- Check with GCTA for comparison
```

---

## Comparison with Other Methods

| Feature | BOLT-LMM | GCTA | LDAK |
|---------|----------|------|------|
| Speed | Fast | Slow | Medium |
| Memory | Higher | Lower | Medium |
| LD-aware | No | No | Yes |
| Binary traits | Basic | Basic | PCGC available |
| Min sample size | 5,000 | 1,000 | 1,000 |

---

## Future Enhancements

The following features may be added in future versions:

1. **Full Association Testing**
   - BOLT-LMM GWAS with `--lmm` flag
   - Leave-one-chromosome-out predictions
   - Result merging across chromosomes

2. **Bayesian Mixed Model**
   - BOLT-LMM-inf for non-infinitesimal model
   - Better for highly polygenic traits

3. **Dosage Support**
   - Direct BGEN/VCF input
   - Skip PLINK1 conversion

---

## References

- Loh et al. (2015). Efficient Bayesian mixed-model analysis increases association power in large cohorts. *Nature Genetics*. https://doi.org/10.1038/ng.3190
- Loh et al. (2018). Mixed-model association for biobank-scale datasets. *Nature Genetics*. https://doi.org/10.1038/s41588-018-0144-6
- [BOLT-LMM Documentation](https://alkesgroup.broadinstitute.org/BOLT-LMM/)
- [BOLT-LMM Manual](https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/BOLT-LMM_manual.html)

---

## Related Workflows

- [GCTA](../gcta/README.md) - Alternative REML, gold standard
- [LDAK](../ldak/README.md) - LD-aware heritability, PCGC for binary traits
- [REGENIE](../regenie/README.md) - GWAS with gene-based tests
