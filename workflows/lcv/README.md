# LCV Workflow

[Back to main README](../../README.md)

LCV (Latent Causal Variable) is a method for inferring genetically causal relationships between traits using GWAS summary statistics. Unlike Mendelian randomization, LCV distinguishes true genetic causality from genetic correlation due to shared genetic factors (horizontal pleiotropy).

## Table of Contents

- [Overview](#overview)
- [When to Use LCV](#when-to-use-lcv)
- [Quick Start](#quick-start)
- [Input Requirements](#input-requirements)
- [Parameters](#parameters)
- [Usage Examples](#usage-examples)
- [Output Files](#output-files)
- [Interpretation Guide](#interpretation-guide)
- [Troubleshooting](#troubleshooting)

---

## Overview

LCV estimates the **Genetic Causal Proportion (GCP)**, which indicates whether the genetic correlation between two traits is driven by causality or shared genetic factors.

| GCP Value | Interpretation |
|-----------|----------------|
| GCP ≈ 1 | Trait 1 is fully genetically causal for Trait 2 |
| GCP ≈ -1 | Trait 2 is fully genetically causal for Trait 1 |
| GCP ≈ 0 | Genetic correlation without causality (pleiotropy) |
| 0 < GCP < 1 | Partial causality from Trait 1 to Trait 2 |

### Key Advantages

- **No instrument selection**: Unlike MR, doesn't require choosing instrumental variables
- **Robust to pleiotropy**: Distinguishes causality from shared genetic factors
- **Summary statistics only**: No individual-level data needed
- **Sample overlap tolerant**: Handles overlapping GWAS samples

### Citation

O'Connor & Price (2018). Distinguishing genetic correlation from causation across 52 diseases and complex traits. *Nature Genetics*. https://doi.org/10.1038/s41588-018-0091-z

---

## When to Use LCV

| Scenario | Recommendation |
|----------|----------------|
| Test genetic causality between traits | **Recommended** |
| Distinguish causality from pleiotropy | **Recommended** |
| Summary statistics available | **Recommended** |
| Individual-level data only | Consider MR methods |
| Direction of causality unclear | **Recommended** |
| Local genetic correlation | Use LAVA instead |

---

## Quick Start

```bash
nextflow run main.nf \
    --project causal_analysis \
    --run_causal_inference true \
    --causal_inference_method lcv \
    --lcv_sumstats1 exposure_gwas.txt \
    --lcv_sumstats2 outcome_gwas.txt \
    --lcv_ldscores ldscores.l2.ldscore.gz \
    --lcv_trait1_name "Exposure" \
    --lcv_trait2_name "Outcome" \
    -profile singularity
```

---

## Input Requirements

### Required Files

| File | Description | Format |
|------|-------------|--------|
| **Summary Stats 1** | GWAS for trait 1 | Tab-separated text |
| **Summary Stats 2** | GWAS for trait 2 | Tab-separated text |
| **LD Scores** | Pre-computed LD scores | LDSC format |

### File Format Details

**Summary Statistics**:
```
SNP         CHR   BP        Z
rs12345     1     100000    3.45
rs67890     1     200000   -2.13
```

Required columns:
- `SNP`: SNP identifier (rsID recommended)
- `Z`: Z-score (effect / SE)

Optional columns:
- `CHR`: Chromosome (for sorting)
- `BP`: Base pair position (for sorting)

**Important**: Data should be sorted by genomic position for accurate jackknife standard errors.

**LD Scores**:
```
SNP         L2
rs12345     25.3
rs67890     18.7
```

Pre-computed LD scores available from:
- [Broad Institute LDSC](https://data.broadinstitute.org/alkesgroup/LDSCORE/)
- [LDSC GitHub](https://github.com/bulik/ldsc)

---

## Parameters

### Essential Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--lcv_sumstats1` | Summary statistics file 1 | Required |
| `--lcv_sumstats2` | Summary statistics file 2 | Required |
| `--lcv_ldscores` | LD scores file | Required |
| `--lcv_trait1_name` | Name for trait 1 | Required |
| `--lcv_trait2_name` | Name for trait 2 | Required |

### Analysis Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--lcv_no_blocks` | Number of jackknife blocks | `100` |
| `--lcv_sig_threshold` | Chi-square significance threshold | `30` |
| `--lcv_crosstrait_intercept` | Estimate cross-trait intercept | `1` (yes) |
| `--lcv_ldsc_intercept` | Estimate LDSC intercept | `1` (yes) |

---

## Usage Examples

### Basic Causal Analysis

```bash
nextflow run main.nf \
    --project bmi_t2d \
    --run_causal_inference true \
    --causal_inference_method lcv \
    --lcv_sumstats1 bmi_gwas.txt \
    --lcv_sumstats2 t2d_gwas.txt \
    --lcv_ldscores eur_w_ld_chr.l2.ldscore.gz \
    --lcv_trait1_name "BMI" \
    --lcv_trait2_name "Type2Diabetes" \
    -profile singularity
```

### Multiple Trait Pairs

Run separately for each pair:

```bash
# BMI → T2D
nextflow run main.nf \
    --project bmi_t2d \
    --run_causal_inference true \
    --causal_inference_method lcv \
    --lcv_sumstats1 bmi_gwas.txt \
    --lcv_sumstats2 t2d_gwas.txt \
    --lcv_ldscores eur_ldscores.l2.ldscore.gz \
    --lcv_trait1_name "BMI" \
    --lcv_trait2_name "T2D" \
    -profile singularity

# LDL → CAD
nextflow run main.nf \
    --project ldl_cad \
    --run_causal_inference true \
    --causal_inference_method lcv \
    --lcv_sumstats1 ldl_gwas.txt \
    --lcv_sumstats2 cad_gwas.txt \
    --lcv_ldscores eur_ldscores.l2.ldscore.gz \
    --lcv_trait1_name "LDL" \
    --lcv_trait2_name "CAD" \
    -profile singularity
```

### With Custom Jackknife Blocks

For more stable standard errors:

```bash
nextflow run main.nf \
    --project precise_lcv \
    --run_causal_inference true \
    --causal_inference_method lcv \
    --lcv_sumstats1 trait1_gwas.txt \
    --lcv_sumstats2 trait2_gwas.txt \
    --lcv_ldscores ldscores.l2.ldscore.gz \
    --lcv_trait1_name "Trait1" \
    --lcv_trait2_name "Trait2" \
    --lcv_no_blocks 200 \
    -profile singularity
```

### Constrained Analysis

When you expect many large-effect SNPs:

```bash
nextflow run main.nf \
    --project constrained_lcv \
    --run_causal_inference true \
    --causal_inference_method lcv \
    --lcv_sumstats1 trait1_gwas.txt \
    --lcv_sumstats2 trait2_gwas.txt \
    --lcv_ldscores ldscores.l2.ldscore.gz \
    --lcv_trait1_name "Trait1" \
    --lcv_trait2_name "Trait2" \
    --lcv_sig_threshold 50 \
    -profile singularity
```

---

## Output Files

### Directory Structure

```
output/project_name/
└── lcv/
    ├── trait1_trait2.lcv.results    # Main results
    └── trait1_trait2.lcv.log        # Analysis log
```

### Results File Contents

```
LCV Analysis Results
====================

Trait 1: BMI
Trait 2: Type2Diabetes

Genetic Correlation:
  rho_g: 0.523
  rho_g SE: 0.034
  rho_g p-value: 1.2e-48

Genetic Causal Proportion:
  GCP: 0.72
  GCP SE: 0.08
  GCP p-value: 3.4e-15

Interpretation:
  Evidence for partial genetic causality from BMI to Type2Diabetes
```

### Key Output Values

| Value | Description |
|-------|-------------|
| `rho_g` | Genetic correlation |
| `rho_g SE` | Standard error of rho_g |
| `GCP` | Genetic causal proportion |
| `GCP SE` | Standard error of GCP |
| `GCP p-value` | Test for GCP ≠ 0 |

---

## Interpretation Guide

### Understanding GCP

```
GCP > 0:  Trait 1 → Trait 2 (causality direction)
GCP < 0:  Trait 2 → Trait 1 (reverse direction)
GCP ≈ 0:  No genetic causality (horizontal pleiotropy)
```

### Significance Interpretation

| p-value | Interpretation |
|---------|----------------|
| p < 0.05 | Evidence for genetic causality |
| p ≥ 0.05 | No significant evidence |

**Important**: Significant p-value alone doesn't tell direction. Use the sign of GCP.

### Strength of Evidence

| |GCP| | Evidence Strength |
|-------|------------------|
| |GCP| > 0.7 | Strong evidence for causality |
| 0.4 < |GCP| ≤ 0.7 | Moderate evidence |
| |GCP| ≤ 0.4 | Weak evidence or partial causality |

### Example Interpretations

**BMI → T2D (GCP = 0.72, p = 3.4e-15)**:
"Strong evidence that BMI is genetically causal for Type 2 Diabetes risk. Approximately 72% of the genetic correlation is driven by causality from BMI to T2D."

**Education ↔ BMI (GCP = 0.12, p = 0.15)**:
"No significant evidence for genetic causality. The genetic correlation between education and BMI appears to be driven by shared genetic factors (horizontal pleiotropy) rather than causality."

---

## Troubleshooting

### Low Power / Non-Significant Results

**Issue**: GCP p-value not significant
```
Possible causes:
1. Insufficient sample sizes
2. True GCP close to 0 (pleiotropy)
3. Bidirectional causality (cancels out)

Solutions:
- Use larger GWAS if available
- Non-significance may be biologically meaningful
- Consider MR for complementary analysis
```

### Unexpected GCP Sign

**Issue**: GCP sign contradicts biological expectation
```
Considerations:
1. Statistical uncertainty (check SE)
2. Reverse causality is real
3. Collider bias in one GWAS

Actions:
- Check confidence intervals
- Review GWAS study designs
- Consider sensitivity analyses
```

### SNP Mismatch

**Error**: "Too few overlapping SNPs"
```
Solutions:
1. Ensure same genome build
2. Use rsID format for SNP matching
3. Impute missing SNPs if needed
4. Minimum ~100k overlapping SNPs recommended
```

### Convergence Issues

**Error**: "LCV did not converge"
```
Solutions:
1. Increase --lcv_no_blocks
2. Check summary statistics quality
3. Remove very significant SNPs (rare)
```

---

## Best Practices

### Data Quality

1. **Filter summary statistics**:
   - Remove MHC region (chr6:25-35Mb)
   - MAF > 0.05 recommended
   - No strand-ambiguous SNPs (A/T, C/G)

2. **Match ancestry**:
   - Summary statistics and LD scores same ancestry
   - European LD scores for European GWAS

3. **Sample size**:
   - Effective N > 50,000 for reliable results
   - More samples = more power

### Analysis Recommendations

1. **Run bidirectionally**: Test A→B and B→A
2. **Compare with MR**: Use for validation
3. **Check genetic correlation first**: Significant rg often needed
4. **Consider multiple testing**: Adjust for many trait pairs

---

## Comparison with Mendelian Randomization

| Feature | LCV | MR |
|---------|-----|-----|
| Instrument selection | No | Yes (required) |
| Horizontal pleiotropy | Robust | Assumption violated |
| Causal effect estimate | No (only GCP) | Yes (beta) |
| Power | Often higher | Depends on instruments |
| Bidirectional | Tests both directions | Typically one direction |

**Recommendation**: Use both LCV and MR as complementary approaches.

---

## References

- O'Connor & Price (2018). Distinguishing genetic correlation from causation across 52 diseases and complex traits. *Nature Genetics*. https://doi.org/10.1038/s41588-018-0091-z
- [LCV GitHub](https://github.com/lukejoconnor/LCV)
- [LCV R Package](https://cran.r-project.org/package=LCV)

---

## Related Workflows

- [LDAK SumCors](../ldak/README.md) - Genetic correlation (without causality)
- [LAVA](../lava/README.md) - Local genetic correlation
- [GCTA Bivariate](../gcta/README.md) - Bivariate GREML (individual data)
