# LAVA Workflow

[Back to main README](../../README.md)

LAVA (Local Analysis of [co]Variant Association) enables local genetic correlation analysis, identifying specific genomic regions where traits share genetic architecture. Unlike genome-wide methods, LAVA tests for genetic overlap at predefined loci, providing regional resolution of genetic relationships.

## Table of Contents

- [Overview](#overview)
- [When to Use LAVA](#when-to-use-lava)
- [Quick Start](#quick-start)
- [Input Requirements](#input-requirements)
- [Parameters](#parameters)
- [Usage Examples](#usage-examples)
- [Output Files](#output-files)
- [Interpretation Guide](#interpretation-guide)
- [Troubleshooting](#troubleshooting)

---

## Overview

LAVA performs two types of analyses:

| Analysis | Purpose | Output |
|----------|---------|--------|
| **Univariate** | Test for local genetic signal at each locus | Local h² per trait |
| **Bivariate** | Estimate local genetic correlation | Local rg between traits |

### Key Advantages

- **Regional resolution**: Identify specific regions driving genetic overlap
- **Multiple traits**: Test many phenotype pairs efficiently
- **Sample overlap**: Correction for overlapping GWAS samples
- **Summary statistics**: No individual-level data required

### Citation

Werme et al. (2022). An integrated framework for local genetic correlation analysis. *Nature Genetics*. https://doi.org/10.1038/s41588-022-01017-y

---

## When to Use LAVA

| Scenario | Recommendation |
|----------|----------------|
| Regional genetic correlation | **Recommended** |
| Identify shared loci between traits | **Recommended** |
| Multiple phenotype pairs | **Recommended** |
| Genome-wide correlation only | Use LDAK SumCors instead |
| Individual-level data available | Can use GCTA bivariate |
| Causal inference | Use LCV instead |

---

## Quick Start

```bash
nextflow run main.nf \
    --project local_rg \
    --run_genetic_correlation true \
    --genetic_correlation_method lava \
    --lava_input_info input_info.txt \
    --lava_loci_file test.loci \
    --lava_ref_plink "reference.{bed,bim,fam}" \
    --lava_phenotypes "trait1,trait2,trait3" \
    -profile singularity
```

---

## Input Requirements

### Required Files

| File | Description | Format |
|------|-------------|--------|
| **Reference Data** | LD reference panel | PLINK1 (bed/bim/fam) |
| **Input Info** | Summary stats metadata | Tab-separated text |
| **Loci File** | Genomic regions to test | Tab-separated text |
| **Summary Statistics** | GWAS results for each trait | Various formats supported |

### Optional Files

| File | Description | Format |
|------|-------------|--------|
| **Sample Overlap** | Cross-trait sample correlation | Matrix format |

### File Format Details

**Input Info File** (`input_info.txt`):
```
phenotype   cases   controls   prevalence   filename
trait1      NA      NA         NA           /path/to/trait1_sumstats.txt
trait2      5000    10000      0.05         /path/to/trait2_sumstats.txt
trait3      NA      NA         NA           /path/to/trait3_sumstats.txt
```

| Column | Description |
|--------|-------------|
| `phenotype` | Trait identifier |
| `cases` | Number of cases (NA for quantitative) |
| `controls` | Number of controls (NA for quantitative) |
| `prevalence` | Population prevalence (optional) |
| `filename` | Path to summary statistics |

**Loci File** (`test.loci`):
```
LOC CHR START STOP
1   1   1000000   2000000
2   1   2500000   3500000
3   1   4000000   5500000
```

Pre-computed loci files are available from the LAVA repository.

**Summary Statistics**:
```
SNP         A1    A2    N       Z
rs12345     A     G     50000   3.45
rs67890     C     T     50000  -2.13
```

Accepted column names:
- SNP: `SNP`, `ID`, `SNPID`, `RSID`, `MarkerName`
- Effect allele: `A1`, `ALT`
- Other allele: `A2`, `REF`
- Sample size: `N`, `NMISS`, `N_analyzed`
- Z-score: `Z`, `T`, `STAT` (or `BETA` + `P`)

**Sample Overlap Matrix** (optional):
```
        trait1  trait2  trait3
trait1  1       0.15    0.08
trait2  0.15    1       0.12
trait3  0.08    0.12    1
```

Diagonal = 1, off-diagonal = sampling correlation (from LDSC intercept).

---

## Parameters

### Essential Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--lava_input_info` | Input info file | Required |
| `--lava_loci_file` | Loci definition file | Required |
| `--lava_ref_plink` | Reference PLINK files | Required |
| `--lava_phenotypes` | Comma-separated trait names | Required |

### Analysis Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--lava_univ_threshold` | P-value threshold for bivariate tests | `0.05` |
| `--lava_sample_overlap` | Sample overlap matrix file | Optional |

The univariate threshold determines which loci proceed to bivariate testing: only phenotype pairs where both pass the threshold are tested.

---

## Usage Examples

### Basic Two-Trait Analysis

```bash
nextflow run main.nf \
    --project local_rg \
    --run_genetic_correlation true \
    --genetic_correlation_method lava \
    --lava_input_info input_info.txt \
    --lava_loci_file european.loci \
    --lava_ref_plink "1kg_eur.{bed,bim,fam}" \
    --lava_phenotypes "depression,anxiety" \
    -profile singularity
```

### Multiple Traits

```bash
nextflow run main.nf \
    --project multi_local_rg \
    --run_genetic_correlation true \
    --genetic_correlation_method lava \
    --lava_input_info input_info.txt \
    --lava_loci_file european.loci \
    --lava_ref_plink "1kg_eur.{bed,bim,fam}" \
    --lava_phenotypes "depression,anxiety,bmi,height,edu" \
    --lava_univ_threshold 0.01 \
    -profile slurm,singularity
```

### With Sample Overlap Correction

```bash
nextflow run main.nf \
    --project local_rg_overlap \
    --run_genetic_correlation true \
    --genetic_correlation_method lava \
    --lava_input_info input_info.txt \
    --lava_loci_file european.loci \
    --lava_ref_plink "1kg_eur.{bed,bim,fam}" \
    --lava_phenotypes "ukb_height,ukb_bmi" \
    --lava_sample_overlap sample_overlap.txt \
    -profile singularity
```

### Stringent Threshold

For hypothesis-generating analyses with many traits:

```bash
nextflow run main.nf \
    --project exploratory_rg \
    --run_genetic_correlation true \
    --genetic_correlation_method lava \
    --lava_input_info input_info.txt \
    --lava_loci_file european.loci \
    --lava_ref_plink "1kg_eur.{bed,bim,fam}" \
    --lava_phenotypes "trait1,trait2,trait3,trait4,trait5" \
    --lava_univ_threshold 0.001 \
    -profile slurm,singularity
```

---

## Output Files

### Directory Structure

```
output/project_name/
└── lava/
    ├── analysis.univ.lava          # Univariate results
    ├── analysis.bivar.lava         # Bivariate results
    └── analysis.lava.log           # Analysis log
```

### Univariate Results (*.univ.lava)

| Column | Description |
|--------|-------------|
| locus | Locus identifier |
| chr | Chromosome |
| start | Start position |
| stop | End position |
| n.snps | Number of SNPs in locus |
| n.pcs | Principal components used |
| phen | Phenotype name |
| h2.obs | Observed-scale local h² |
| h2.latent | Liability-scale local h² (if binary) |
| p | P-value for h² > 0 |

### Bivariate Results (*.bivar.lava)

| Column | Description |
|--------|-------------|
| locus | Locus identifier |
| chr | Chromosome |
| start | Start position |
| stop | End position |
| n.snps | Number of SNPs |
| n.pcs | Principal components |
| phen1 | First phenotype |
| phen2 | Second phenotype |
| rho | Local genetic correlation |
| rho.lower | 95% CI lower bound |
| rho.upper | 95% CI upper bound |
| r2 | Coefficient of determination |
| p | P-value for rho ≠ 0 |

---

## Interpretation Guide

### Understanding Local h²

- Tests whether there is genetic signal at this locus
- Significant p-value suggests genetic variants affecting the trait
- Required for bivariate testing (both traits must pass threshold)

### Understanding Local rg (ρ)

| ρ Value | Interpretation |
|---------|----------------|
| ρ ≈ 1 | Perfect positive local correlation |
| ρ ≈ -1 | Perfect negative local correlation |
| ρ ≈ 0 | No local genetic correlation |
| |ρ| > 0.5 | Strong local correlation |
| |ρ| = 0.2-0.5 | Moderate correlation |

### Multiple Testing

With many loci, apply appropriate correction:

```bash
# Bonferroni: 0.05 / (n_loci * n_pairs)
# FDR: Use p.adjust() in R with method="BH"
```

### Comparing to Genome-Wide rg

- Genome-wide rg averages across all loci
- Local rg can be positive at some loci, negative at others
- This reveals heterogeneous genetic architecture

---

## Troubleshooting

### No Bivariate Results

**Issue**: Bivariate file is empty
```
Cause: No loci passed univariate threshold for both traits

Solutions:
1. Lower --lava_univ_threshold (e.g., 0.1)
2. Check univariate results for each trait
3. Traits may not have detectable local h²
```

### SNP Mismatch

**Error**: "SNPs not found in reference"
```
Solutions:
1. Ensure same genome build (all GRCh37 or all GRCh38)
2. Check SNP ID format (rs IDs preferred)
3. Use matched reference panel ancestry
```

### Sample Overlap Issues

**Warning**: "Sample overlap may affect results"
```
Solutions:
1. Create sample overlap matrix using LDSC intercept
2. Diagonal elements should be 1
3. Off-diagonal = sampling correlation estimate
```

### Memory Errors

**Error**: "Cannot allocate memory"
```
Solutions:
1. Reduce number of loci analyzed at once
2. Increase memory allocation
3. Use smaller reference panel
```

### Reference Panel Selection

**Recommendation**:
- European: Use UK Biobank or 1000 Genomes EUR
- Other ancestries: Match to summary statistics population
- Avoid small reference panels (< 500 individuals)

---

## Best Practices

### Locus Definition

1. **Use pre-computed loci**: Available from LAVA repository
2. **Avoid MHC region**: Chr6:25-35 Mb has complex LD
3. **Consistent build**: Loci and summary stats same build

### Quality Control

1. **Filter summary statistics**:
   - MAF > 0.01
   - INFO > 0.9 (if available)
   - Sample size consistent

2. **Check univariate results first**:
   - Identify traits with detectable local h²
   - Adjust threshold if needed

3. **Consider multiple testing**:
   - Bonferroni for hypothesis testing
   - FDR for discovery

---

## References

- Werme et al. (2022). An integrated framework for local genetic correlation analysis. *Nature Genetics*. https://doi.org/10.1038/s41588-022-01017-y
- [LAVA GitHub](https://github.com/josefin-werme/LAVA)
- [LAVA Partitioning](https://github.com/cadeleeuw/lava-partitioning)

---

## Related Workflows

- [LDAK SumCors](../ldak/README.md) - Genome-wide genetic correlation
- [GCTA Bivariate](../gcta/README.md) - Bivariate GREML (individual data)
- [LCV](../lcv/README.md) - Causal inference between traits
