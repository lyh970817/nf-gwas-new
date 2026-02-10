# GCTA Workflows

[Back to main README](../../README.md)

GCTA (Genome-wide Complex Trait Analysis) provides gold-standard methods for heritability estimation, genetic correlation, and association testing using genetic relationship matrices (GRMs).

## Table of Contents

- [Overview](#overview)
- [Available Workflows](#available-workflows)
- [When to Use GCTA](#when-to-use-gcta)
- [Quick Start](#quick-start)
- [Input Requirements](#input-requirements)
- [Parameters](#parameters)
- [Usage Examples](#usage-examples)
- [Output Files](#output-files)
- [Method Selection Guide](#method-selection-guide)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

---

## Overview

GCTA implements several key methods:

| Workflow | Purpose | Method |
|----------|---------|--------|
| **GCTA GREML** | Heritability estimation | Genomic REML |
| **GCTA GREML-LDMS** | Partitioned heritability | LD-stratified REML |
| **GCTA FastGWA** | Association testing | Sparse GRM mixed model |
| **Bivariate GREML** | Genetic correlation | Bivariate REML |

### Key Advantages

- **Gold standard**: Most widely cited heritability method
- **Accurate**: REML provides maximum likelihood estimates
- **Flexible**: Multiple variance components
- **Established**: Well-validated across many studies

---

## Available Workflows

### 1. GCTA GREML
Standard heritability estimation using a single GRM.

### 2. GCTA GREML-LDMS
Partitioned heritability by LD score bins. Tests whether high-LD regions contribute more to heritability.

### 3. GCTA FastGWA
Fast mixed model GWAS using sparse GRM. Suitable for large biobank datasets.

### 4. Bivariate GREML
Genetic correlation between two traits measured in the same samples.

### 5. Bivariate GREML-LDMS
Genetic correlation with LD-stratified variance components.

---

## When to Use GCTA

| Scenario | Recommendation |
|----------|----------------|
| Heritability (gold standard) | **GCTA GREML** |
| Partitioned heritability by LD | **GCTA GREML-LDMS** |
| Genetic correlation (same cohort) | **Bivariate GREML** |
| Fast GWAS (N > 50k) | **GCTA FastGWA** |
| Large samples with speed needed | Consider LDAK HE or BOLT-LMM |
| Binary traits (case-control) | Consider LDAK PCGC instead |
| Summary statistics only | Use LDAK SumHer/SumCors |

---

## Quick Start

### Heritability Estimation

```bash
nextflow run main.nf \
    --project heritability \
    --run_heritability_estimation true \
    --heritability_method gcta_greml \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --phenotypes_dir phenotypes/ \
    -profile singularity
```

### Association Testing

```bash
nextflow run main.nf \
    --project gwas \
    --run_association_analysis true \
    --association_method gcta_fastgwa \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --phenotypes_dir phenotypes/ \
    -profile singularity
```

---

## Input Requirements

### Required Files

| File | Description | Format |
|------|-------------|--------|
| **Genotypes** | SNP data | PLINK2 (pgen/psam/pvar) preferred |
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
```

**Covariate File**:
```
FID    IID    age    sex    PC1       PC2
1001   1001   45     1      0.0123   -0.0089
1002   1002   52     2      0.0031    0.0156
```

---

## Parameters

### GRM Calculation

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--nparts_gcta` | Number of parallel GRM parts | `10` |

Higher values increase parallelization but also I/O overhead. Recommended: 10-20 for large datasets.

### GREML Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--phenotypes_dir` | Directory of phenotype files (one trait per file) | Required |
| `--covariates_filename` | Covariate file path | Optional |
| `--covariates_columns` | Quantitative covariates | Optional |
| `--covariates_cat_columns` | Categorical covariates | Optional |

### FastGWA Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--gcta_sparse_cutoff` | Sparse GRM threshold | `0.05` |

Individuals with GRM values below this threshold are set to zero, creating a sparse matrix for faster computation.

---

## Usage Examples

### Standard GREML Heritability

```bash
nextflow run main.nf \
    --project h2_study \
    --run_heritability_estimation true \
    --heritability_method gcta_greml \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --phenotypes_dir phenotypes/ \
    --covariates_filename covariates.txt \
    --covariates_columns age,PC1,PC2,PC3,PC4,PC5 \
    --covariates_cat_columns sex \
    --nparts_gcta 20 \
    -profile slurm,singularity
```

### GREML-LDMS (Partitioned Heritability)

```bash
nextflow run main.nf \
    --project h2_ldms \
    --run_heritability_estimation true \
    --heritability_method gcta_greml_ldms \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

Note: GREML-LDMS requires both PLINK1 (for LD score calculation) and PLINK2 formats.

### FastGWA Association Testing

```bash
nextflow run main.nf \
    --project fastgwa \
    --run_association_analysis true \
    --association_method gcta_fastgwa \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --phenotypes_dir phenotypes/ \
    --covariates_filename covariates.txt \
    --covariates_columns age,sex,PC1,PC2,PC3 \
    --gcta_sparse_cutoff 0.05 \
    -profile slurm,singularity
```

### Bivariate GREML (Genetic Correlation)

```bash
nextflow run main.nf \
    --project genetic_corr \
    --run_genetic_correlation true \
    --genetic_correlation_method gcta_bivariate \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

### Multiple Phenotypes (Batch Analysis)

```bash
nextflow run main.nf \
    --project multi_h2 \
    --run_heritability_estimation true \
    --heritability_method gcta_greml \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

---

## Output Files

### Directory Structure

```
output/project_name/
├── gcta/
│   ├── grm/
│   │   ├── gcta_grm.grm.id         # Sample IDs
│   │   ├── gcta_grm.grm.bin        # GRM values (binary)
│   │   └── gcta_grm.grm.N.bin      # SNP counts
│   │
│   ├── greml/
│   │   └── phenotype.hsq           # Heritability results
│   │
│   ├── greml_ldms/
│   │   ├── ld_scores/              # LD score files
│   │   └── phenotype.hsq           # Partitioned h² results
│   │
│   ├── fastgwa/
│   │   ├── chr01.fastGWA           # Per-chromosome results
│   │   └── ...
│   │
│   └── bivariate/
│       └── trait1_trait2.hsq       # Genetic correlation
```

### Heritability Results (*.hsq)

```
Source	Variance	SE
V(G)	0.4523	0.0234
V(e)	0.5477	0.0234
Vp	    1.0000	0.0142
V(G)/Vp	0.4523	0.0234

logL	-12345.67
logL0	-12456.78
LRT	    222.22
df	    1
Pval	1.23e-49
n	    50000
```

Key values:
- `V(G)/Vp`: SNP heritability (h²)
- `SE`: Standard error
- `Pval`: Significance of genetic variance component

### FastGWA Results (*.fastGWA)

| Column | Description |
|--------|-------------|
| CHR | Chromosome |
| SNP | Variant ID |
| POS | Position |
| A1 | Effect allele |
| A2 | Other allele |
| N | Sample size |
| AF1 | Effect allele frequency |
| BETA | Effect size |
| SE | Standard error |
| P | P-value |

### Bivariate Results

```
Source	rG	     SE	      Pval
rG	    0.523	 0.045	  1.2e-32
```

- `rG`: Genetic correlation
- `SE`: Standard error
- `Pval`: Significance of correlation

---

## Method Selection Guide

### GREML vs GREML-LDMS

| Feature | GREML | GREML-LDMS |
|---------|-------|------------|
| Speed | Faster | Slower |
| Precision | Good | Better for LD-dependent architecture |
| Components | 1 | 4 (by LD quartile) |
| Use case | Standard h² | Testing LD-stratified enrichment |

### FastGWA vs REGENIE

| Feature | FastGWA | REGENIE |
|---------|---------|---------|
| Speed | Fast | Fast |
| Memory | Higher | Lower |
| Gene-based tests | No | Yes |
| Interaction tests | No | Yes |
| Firth correction | No | Yes |

---

## Performance Tips

### Memory Management

| Sample Size | Recommended `nparts_gcta` | Expected Memory |
|-------------|---------------------------|-----------------|
| N < 10,000 | 5-10 | ~16 GB |
| N = 10,000-50,000 | 10-20 | ~64 GB |
| N = 50,000-100,000 | 20-50 | ~128 GB |
| N > 100,000 | 50-100 | ~256 GB+ |

### Speed Optimization

1. **Use PLINK2 format**: Faster reading than PLINK1
2. **Increase parallelization**: Higher `nparts_gcta` on HPC
3. **Use sparse GRM for FastGWA**: Default `--gcta_sparse_cutoff 0.05`
4. **Consider alternatives**: LDAK HE is 10-100x faster for h²

### Best Practices

1. **Remove related individuals**: GRM cutoff 0.05 is applied automatically
2. **Include principal components**: At least PC1-PC10 as covariates
3. **Check convergence**: Verify logL in output files
4. **QC genotypes**: MAF > 1%, call rate > 95%

---

## Troubleshooting

### GRM Calculation Fails

**Error**: "Memory allocation failed"
```
Solution: Increase --nparts_gcta to reduce per-job memory
Also try reducing variant count through more stringent QC
```

**Error**: "No valid variants"
```
Solution: Check PLINK files for proper formatting
Verify MAF and call rate filters aren't too stringent
```

### GREML Doesn't Converge

**Error**: "REML analysis did not converge"
```
Possible causes:
1. Small sample size (N < 1000)
2. Too many variance components for data
3. Heritability close to 0 or 1

Solutions:
- Increase sample size if possible
- Use simpler model (single component)
- Check phenotype distribution
```

### Negative Heritability

**Output**: `V(G)/Vp = -0.05`
```
This can occur due to:
1. Sampling variance (small sample)
2. Model misspecification
3. True h² close to zero

Interpretation:
- Constrain to 0 for reporting
- SE overlapping 0 suggests non-significant h²
```

### Related Individuals Warning

**Warning**: "Found 500 pairs with GRM > 0.05"
```
This is handled automatically. GCTA removes one individual
from each related pair. Check output for final sample size.
```

### FastGWA Issues

**Error**: "Sparse GRM is empty"
```
Solution: Lower --gcta_sparse_cutoff (try 0.025)
This keeps more GRM values non-zero
```

---

## References

- Yang et al. (2011). GCTA: a tool for genome-wide complex trait analysis. *American Journal of Human Genetics*. https://doi.org/10.1016/j.ajhg.2010.11.011
- Yang et al. (2015). Genetic variance estimation with imputed variants finds negligible missing heritability for human height and body mass index. *Nature Genetics*.
- Jiang et al. (2019). A resource-efficient tool for mixed model association analysis of large-scale data. *Nature Genetics*. https://doi.org/10.1038/s41588-019-0530-8
- [GCTA Documentation](https://yanglab.westlake.edu.cn/software/gcta/)

---

## Related Workflows

- [LDAK](../ldak/README.md) - LD-aware heritability (faster HE regression available)
- [BOLT-LMM](../bolt_lmm/README.md) - Alternative fast REML
- [REGENIE](../regenie/README.md) - Association testing with gene-based tests
