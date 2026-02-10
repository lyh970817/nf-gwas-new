# LDAK Workflows

[Back to main README](../../README.md)

LDAK (LD-Adjusted Kinships) provides advanced methods for heritability estimation, genetic correlation, and association testing that account for linkage disequilibrium patterns in the genome. LDAK methods often provide more accurate estimates than standard approaches by properly weighting SNPs based on LD structure.

## Table of Contents

- [Overview](#overview)
- [Available Workflows](#available-workflows)
- [When to Use LDAK](#when-to-use-ldak)
- [Quick Start](#quick-start)
- [Input Requirements](#input-requirements)
- [Parameters](#parameters)
- [Usage Examples](#usage-examples)
- [Output Files](#output-files)
- [Method Selection Guide](#method-selection-guide)
- [Heritability Models](#heritability-models)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

---

## Overview

LDAK implements several key methods:

| Workflow | Purpose | Data Type |
|----------|---------|-----------|
| **LDAK-KVIK** | Fast GWAS | Individual-level |
| **LDAK REML** | Heritability (accurate) | Individual-level |
| **LDAK HE** | Heritability (fast) | Individual-level |
| **LDAK PCGC** | Heritability (binary traits) | Individual-level |
| **LDAK QC** | Quality control | Individual-level |
| **LDAK SumHer** | Heritability | Summary statistics |
| **LDAK SumCors** | Genetic correlation | Summary statistics |

Note: LDSC summary-statistics workflows are implemented separately under `workflows/ldsc/` (`ldsc_h2` and `ldsc_rg`).

### Key Advantages

- **LD-aware**: Accounts for linkage disequilibrium patterns
- **Flexible**: Multiple heritability models
- **Fast**: HE regression 10-100x faster than REML
- **Binary traits**: PCGC for liability-scale heritability
- **Summary statistics**: No individual data needed for SumHer/SumCors

---

## Available Workflows

### 1. LDAK-KVIK (Association Testing)
Fast mixed-model GWAS that is faster than REGENIE with power comparable to BOLT-LMM.

### 2. LDAK REML (Heritability)
Standard REML heritability estimation with LD-aware kinship matrices.

### 3. LDAK HE (Fast Heritability)
Haseman-Elston regression for rapid heritability estimation. 10-100x faster than REML, ideal for large samples or preliminary analysis.

### 4. LDAK PCGC (Binary Traits)
PCGC regression for liability-scale heritability in case-control studies. Essential for binary phenotypes.

### 5. LDAK QC (Quality Control)
Quality control workflow with inflation testing via chromosome quartering.

### 6. LDAK SumHer (Summary Statistics Heritability)
Estimate heritability from GWAS summary statistics without individual-level data.

### 7. LDAK SumCors (Genetic Correlation)
Estimate genetic correlation between traits using summary statistics.

---

## When to Use LDAK

| Scenario | Recommended Workflow |
|----------|---------------------|
| Fast GWAS (biobank-scale) | **LDAK-KVIK** |
| Heritability (quantitative, N > 100k) | **LDAK HE** (fast) |
| Heritability (quantitative, accurate) | **LDAK REML** |
| Heritability (binary/case-control) | **LDAK PCGC** |
| Heritability (summary stats only) | **LDAK SumHer** |
| Genetic correlation (summary stats) | **LDAK SumCors** |
| Quality control / inflation testing | **LDAK QC** |
| Gene-based tests | Use REGENIE instead |

---

## Quick Start

### Fast GWAS with LDAK-KVIK

```bash
nextflow run main.nf \
    --project kvik_gwas \
    --run_association_analysis true \
    --association_method ldak_kvik \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --genotypes_prediction "data/merged.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile singularity
```

### Fast Heritability Estimation

```bash
nextflow run main.nf \
    --project h2_fast \
    --run_heritability_estimation true \
    --heritability_method ldak_he \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile singularity
```

### Binary Trait Heritability

```bash
nextflow run main.nf \
    --project h2_binary \
    --run_heritability_estimation true \
    --heritability_method ldak_pcgc \
    --ldak_pcgc_prevalence 0.05 \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile singularity
```

---

## Input Requirements

### Individual-Level Data

| File | Description | Format |
|------|-------------|--------|
| **Genotypes** | SNP data | PLINK1 (bed/bim/fam) |
| **Phenotypes** | Trait values (one file per trait) | Tab-separated text |
| **Covariates** | Adjustment variables (optional) | Tab-separated text |

### Summary Statistics (SumHer/SumCors)

| File | Description | Format |
|------|-------------|--------|
| **Summary Stats** | GWAS results | Standard GWAS format |
| **Tagging File** | Pre-computed LD tags | LDAK tagging format |

### File Format Examples

**Phenotype Files (one per trait)**:
```
phenotypes/
├── height.txt
└── disease.txt
```

Each file:
```
FID    IID    height
1001   1001   175.5
1002   1002   162.3
```

**Summary Statistics** (for SumHer):
```
Predictor       A1    A2    n       Z
rs12345         A     G     50000   3.45
rs67890         C     T     50000  -2.13
```

Required columns:
- `Predictor` or `SNP`: SNP identifier
- `A1`: Effect allele
- `A2`: Other allele
- `n` or `N`: Sample size
- `Z`: Z-score (or provide `BETA` and `SE`)

---

## Parameters

### General Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--heritability_model` | Kinship model | `human_default` |
| `--phenotypes_dir` | Directory of phenotype files (one trait per file) | Required |

### LDAK-KVIK Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--genotypes_prediction` | Merged PLINK files for Step 1 | Required |
| `--genotypes_association_plink1` | Per-chromosome PLINK files | Required |
| `--covariates_columns` | Quantitative covariates passed to KVIK as `--covar` (if omitted, all non-categorical columns are used) | Optional |
| `--covariates_cat_columns` | Categorical covariates passed to KVIK as `--factors` | Optional |

### HE Regression Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--ldak_use_he_regression` | Enable HE regression | `false` |

### REML Binary-Trait Parameter

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--ldak_reml_prevalence` | Optional population prevalence for binary traits when using `ldak_reml`; passed as `--prevalence` only for traits marked binary | `null` |

### PCGC Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--ldak_run_pcgc` | Enable PCGC regression | `false` |
| `--ldak_pcgc_prevalence` | Population disease prevalence | Required for PCGC |

### SumHer/SumCors Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--summary_stats_dir` | Summary statistics directory | Required |
| `--ldak_sumher_tagfile` | Tagging file | Required |
| `--ldak_sumher_prevalence` | Disease prevalence (binary) | Optional |
| `--ldak_sumher_ascertainment` | Sample case fraction / ascertainment (binary) | Optional |
| `--ldak_sumher_prevalence_map` | Optional file mapping summary stats filename to prevalence (`<filename> <prevalence>`) | Optional |
| `--ldak_sumher_ascertainment_map` | Optional file mapping summary stats filename to ascertainment (`<filename> <ascertainment>`) | Optional |

### QC Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--batch_subset_prefix` | Batch identifier prefix | Optional |
| `--batch_subset_number` | Number of batches | Optional |

---

## Usage Examples

### LDAK-KVIK GWAS

The fastest mixed-model GWAS available, with power comparable to BOLT-LMM.

```bash
nextflow run main.nf \
    --project kvik_gwas \
    --run_association_analysis true \
    --association_method ldak_kvik \
    --genotypes_prediction "data/merged.{bed,bim,fam}" \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    --covariates_filename covariates.txt \
    --covariates_columns age,sex,PC1,PC2,PC3 \
    -profile slurm,singularity
```

### LDAK REML Heritability

Standard REML with LD-aware kinship:

```bash
nextflow run main.nf \
    --project h2_reml \
    --run_heritability_estimation true \
    --heritability_method ldak_reml \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    --heritability_model human_default \
    -profile slurm,singularity
```

For binary traits with REML, optionally provide population prevalence:

```bash
nextflow run main.nf \
    --project h2_reml_binary \
    --run_heritability_estimation true \
    --heritability_method ldak_reml \
    --ldak_reml_prevalence 0.05 \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

Note: `--ldak_reml_prevalence` is only applied to traits detected as binary by phenotype metadata.

### LDAK HE Regression (Fast)

10-100x faster than REML, ideal for large samples:

```bash
nextflow run main.nf \
    --project h2_fast \
    --run_heritability_estimation true \
    --heritability_method ldak_he \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

### LDAK PCGC (Binary Traits)

For case-control studies with known disease prevalence:

```bash
nextflow run main.nf \
    --project h2_disease \
    --run_heritability_estimation true \
    --heritability_method ldak_pcgc \
    --ldak_pcgc_prevalence 0.05 \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

**Important**: Use population prevalence, not sample case fraction!

### LDAK QC (Quality Control)

Test for inflation due to population structure:

```bash
nextflow run main.nf \
    --project qc_analysis \
    --run_qc true \
    --qc_method ldak_qc \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile singularity
```

### SumHer (Summary Statistics Heritability)

Estimate h² from GWAS summary statistics:

```bash
nextflow run main.nf \
    --project sumher_h2 \
    --run_heritability_estimation true \
    --heritability_method ldak_sumher \
    --summary_stats_dir gwas_stats/ \
    --ldak_sumher_tagfile bld.ldak.hapmap.gbr.tagging \
    -profile singularity
```

For mixed continuous/binary traits, provide per-file prevalence mapping:

```bash
nextflow run main.nf \
    --project sumher_h2 \
    --run_heritability_estimation true \
    --heritability_method ldak_sumher \
    --summary_stats_dir gwas_stats/ \
    --ldak_sumher_tagfile bld.ldak.hapmap.gbr.tagging \
    --ldak_sumher_prevalence_map prevalence_map.txt \
    --ldak_sumher_ascertainment_map ascertainment_map.txt \
    -profile singularity
```

`prevalence_map.txt` format (whitespace-separated, `#` comments allowed):

```text
# filename prevalence
trait1.sumstats.txt 0.07
trait2.sumstats.txt 0.02
```

Matching is done by summary stats basename. If no entry exists for a file, prevalence is not passed for that trait.
If a prevalence map is provided, legacy global prevalence flag (`--ldak_sumher_prevalence`) is ignored.

`ascertainment_map.txt` uses the same format:

```text
# filename ascertainment
trait1.sumstats.txt 0.50
trait2.sumstats.txt 0.18
```

If an ascertainment map is provided, legacy global ascertainment flag (`--ldak_sumher_ascertainment`) is ignored.

### SumCors (Genetic Correlation)

Estimate genetic correlation from two GWAS:

```bash
nextflow run main.nf \
    --project genetic_corr \
    --run_genetic_correlation true \
    --genetic_correlation_method ldak_sumcors \
    --summary_stats_dir gwas_stats/ \
    --ldak_sumcors_tagfile bld.ldak.hapmap.gbr.tagging \
    -profile singularity
```

Note: LDAK `--sum-cors` does not accept `--prevalence` / `--ascertainment` flags.

### Multiple Phenotypes

Analyze multiple traits in one run:

```bash
nextflow run main.nf \
    --project multi_h2 \
    --run_heritability_estimation true \
    --heritability_method ldak_he \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_dir phenotypes/ \
    -profile slurm,singularity
```

---

## Output Files

### Directory Structure

```
output/project_name/
├── ldak/
│   ├── kinships/
│   │   ├── chr01.grm.bin           # Per-chromosome kinships
│   │   ├── chr01.grm.id
│   │   └── ...
│   │
│   ├── reml/
│   │   ├── phenotype.reml          # REML results
│   │   ├── phenotype.coeff
│   │   └── phenotype.progress
│   │
│   ├── he/
│   │   └── phenotype.he            # HE regression results
│   │
│   ├── pcgc/
│   │   └── phenotype.pcgc          # PCGC results (liability scale)
│   │
│   ├── kvik/
│   │   ├── kvik.step1.root         # Step 1 model
│   │   ├── kvik.step2.assoc        # GWAS results
│   │   └── kvik.step2.summaries    # Optional merged per-chromosome summaries
│   │
│   ├── sumher/
│   │   ├── trait.hers              # Heritability estimates
│   │   └── trait.enrich            # Enrichment (optional)
│   │
│   └── sumcors/
│       └── trait1_trait2.cors      # Genetic correlation
```

### REML Results (*.reml)

```
Component    Heritability    SD         Scaling
Her_ALL      0.452           0.023      1.000

Hepatribility on Liability scale: 0.452 (SD 0.023)
```

### HE Regression Results (*.he)

```
Her_All    Her_SD
0.445      0.031
```

### PCGC Results (*.pcgc)

```
Hepatribility on Liability scale: 0.523 (SD 0.034)
Prevalence used: 0.05
```

### KVIK Association Results (*.assoc)

| Column | Description |
|--------|-------------|
| Predictor | SNP ID |
| Chr | Chromosome |
| Position | Base pair position |
| A1 | Effect allele |
| A2 | Other allele |
| MAF | Minor allele frequency |
| n | Sample size |
| Direction | Effect direction |
| Stat | Test statistic |
| P | P-value |

### SumCors Results (*.cors)

```
Hepatrability 1: 0.423 (SD 0.021)
Hepatrability 2: 0.387 (SD 0.019)
Hepatrgenetic Correlation: 0.654 (SD 0.045)
P-value: 3.2e-48
```

---

## Method Selection Guide

### Heritability Method Comparison

| Method | Speed | Precision | Best For |
|--------|-------|-----------|----------|
| LDAK REML | Slow | High | Final estimates, publication |
| LDAK HE | Very Fast | Medium | Large N (>100k), screening |
| LDAK PCGC | Medium | High | Binary traits |
| GCTA GREML | Slow | High | Comparison, gold standard |

### When to Use Each Method

```
Quantitative Trait + Small N (<10k)  →  LDAK REML
Quantitative Trait + Large N (>100k) →  LDAK HE (then REML for final)
Binary Trait (any N)                  →  LDAK PCGC
Summary Statistics Only               →  LDAK SumHer
```

### GWAS Method Comparison

| Method | Speed | Power | Gene Tests |
|--------|-------|-------|------------|
| LDAK-KVIK | Fastest | High | Yes |
| REGENIE | Fast | High | Yes |
| BOLT-LMM | Medium | High | No |
| GCTA FastGWA | Fast | Medium | No |

---

## Heritability Models

LDAK supports different models for kinship calculation:

| Model | Description | Use Case |
|-------|-------------|----------|
| `human_default` | Power -0.25, LD-aware | Standard for human GWAS |
| `uniform` | Equal weighting (power 0) | Compare with GCTA |
| `ldak-thin` | LD-thinned weights | Alternative LD handling |

### Recommendation

Use `human_default` for most human GWAS analyses. This model downweights SNPs in high-LD regions, reducing inflation from LD tagging.

---

## Performance Tips

### Speed Optimization

1. **Use HE for large samples**: 10-100x faster than REML
2. **LDAK-KVIK for GWAS**: Faster than REGENIE
3. **Pre-compute tagging files**: For repeated SumHer analyses
4. **Chromosome parallelization**: Automatic in the pipeline

### Memory Management

| Analysis | Expected Memory |
|----------|-----------------|
| Kinship (N=50k) | ~32 GB |
| Kinship (N=100k) | ~64 GB |
| REML | ~16 GB |
| HE Regression | ~8 GB |
| SumHer | ~4 GB |

### Sample Size Requirements

| Method | Minimum N | Recommended N |
|--------|-----------|---------------|
| LDAK REML | 1,000 | 10,000+ |
| LDAK HE | 5,000 | 50,000+ |
| LDAK PCGC | 2,000 cases | 5,000+ cases |
| LDAK-KVIK | 5,000 | 50,000+ |

---

## Troubleshooting

### Kinship Calculation Fails

**Error**: "Too few predictors"
```
Solution:
- Ensure genotype files have sufficient variants
- Check MAF filter isn't too stringent
- Verify PLINK files are properly formatted
```

### REML Doesn't Converge

**Error**: "REML failed to converge"
```
Possible causes:
1. Small sample size
2. Heritability near 0 or 1
3. Too few SNPs

Solutions:
- Increase sample size
- Use HE regression instead
- Check phenotype distribution
```

### PCGC Requires Prevalence

**Error**: "Prevalence must be specified for PCGC"
```
Solution: Add --ldak_pcgc_prevalence with population prevalence
Example: --ldak_pcgc_prevalence 0.05 for 5% disease prevalence

Note: Use POPULATION prevalence, not your sample's case fraction!
```

### Negative Heritability

**Output**: `Her_ALL = -0.02`
```
This can occur due to sampling variance.
Interpretation:
- Constrain to 0 for reporting
- True h² is likely very small
- Check SE: if SE > |h²|, not significant
```

### Inflation in QC

**Output**: `Inflation factor = 1.15`
```
Inflation > 1.05 suggests:
1. Population structure not fully controlled
2. Relatedness in sample
3. True polygenicity (may be fine)

Solutions:
- Add more PCs as covariates
- Remove more related individuals
- If consistent across quarters, may be polygenicity
```

### SumHer/SumCors Tagging File Issues

**Error**: "Tagging file not found" or "SNP mismatch"
```
Solution:
1. Download tagging files from LDAK website
2. Ensure same genome build as summary stats
3. Match ancestry (e.g., GBR for European)

Tagging files available at: https://dougspeed.com/ldak/
```

---

## References

- Speed et al. (2012). Improved heritability estimation from genome-wide SNPs. *American Journal of Human Genetics*. https://doi.org/10.1016/j.ajhg.2012.10.010
- Speed et al. (2017). Reevaluation of SNP heritability in complex human traits. *Nature Genetics*. https://doi.org/10.1038/ng.3865
- Speed & Balding (2019). SumHer better estimates the SNP heritability of complex traits from summary statistics. *Nature Genetics*. https://doi.org/10.1038/s41588-018-0279-5
- [LDAK Documentation](https://dougspeed.com/ldak/)
- [LDAK-KVIK Documentation](https://www.ldak-kvik.com)

---

## Related Workflows

- [REGENIE](../regenie/README.md) - Alternative GWAS with gene-based tests
- [GCTA](../gcta/README.md) - Gold-standard GREML
- [BOLT-LMM](../bolt_lmm/README.md) - Alternative fast mixed model
- [LAVA](../lava/README.md) - Local genetic correlation
- [LCV](../lcv/README.md) - Causal inference
