# Analysis Types and Workflow Mapping

This document provides comprehensive mapping of workflows to the three primary analysis types supported by nf-gwas.

[Root Documentation](../CLAUDE.md)

---

## 1. Association Analysis Workflows

**Purpose**: Identify genetic variants (SNPs) significantly associated with a phenotype

| Workflow | Location | Method | Best For |
|----------|----------|--------|----------|
| `regenie.nf` | `workflows/regenie/` | REGENIE two-step regression | Large biobank datasets (N > 100k), gene-based tests |
| `regenie_step1.nf` | `workflows/regenie/` | REGENIE Step 1 (prediction) | Whole genome regression model building |
| `regenie_step2.nf` | `workflows/regenie/` | REGENIE Step 2 (association) | Single-variant and gene-based tests |
| `gcta_fastgwa.nf` | `workflows/gcta/` | GCTA FastGWA | Fast mixed model association (alternative to REGENIE) |
| `single_variant_tests.nf` | `workflows/` | REGENIE orchestrator | Automated single-variant testing pipeline |

**Entry Point**: `workflows/nf_gwas.nf` → Calls `SINGLE_VARIANT_TESTS`

**Key Features**:
- Handles both quantitative and binary traits
- Supports interaction tests (GxE, GxG)
- Gene-based burden and variance tests
- Conditional analyses

**Typical Usage**:
```bash
nextflow run main.nf \
    --project my_gwas \
    --genotypes_association "data/chr*.vcf.gz" \
    --genotypes_prediction "data/genotypes.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns trait1,trait2 \
    -profile slurm_singularity
```

---

## 2. Heritability Estimation Workflows

**Purpose**: Estimate the proportion of phenotypic variance explained by genetic variants (h²)

### Individual-level Data Methods

| Workflow | Location | Method | Speed | Best For |
|----------|----------|--------|-------|----------|
| `gcta_greml.nf` | `workflows/gcta/` | GCTA GREML | Slow | Gold standard REML for quantitative traits |
| `gcta_greml_ldms.nf` | `workflows/gcta/` | GCTA GREML-LDMS | Slow | GREML with LD score adjustment |
| `bolt_lmm_reml.nf` | `workflows/bolt_lmm/` | BOLT-LMM REML | Fast | Fast REML for large datasets (N > 5k), biobank-scale |
| `ldak.nf` | `workflows/ldak/` | LDAK REML | Slow | LD-aware REML heritability |
| `ldak_he.nf` | `workflows/ldak/` | LDAK HE regression | **Fast** (10-100x) | Large datasets (N > 100k), quantitative traits |
| `ldak_pcgc.nf` | `workflows/ldak/` | LDAK PCGC | Medium | **Binary traits** (liability-scale h²) |
| `ldak_qc.nf` | `workflows/ldak/` | LDAK QC + inflation | Fast | Quality control, inflation testing |

**GRM Calculation** (required for individual-level methods):
- `workflows/gcta/gcta_grm.nf` - GCTA GRM calculation
- `workflows/ldak/calc_kins.nf` - LDAK kinship calculation with LD weighting

### Summary Statistics Methods

| Workflow | Location | Method | Input Required |
|----------|----------|--------|----------------|
| `ldak_sumher.nf` | `workflows/ldak/` | LDAK SumHer | GWAS summary statistics + LD tagging file |

**Entry Point**: `workflows/nf_gwas.nf` → Calls `LDAK_QC` (currently active)

**Key Features**:
- REML: Maximum likelihood, most accurate, computationally intensive
- HE Regression: 10-100x faster than REML, slight accuracy trade-off
- PCGC: Converts observed-scale h² to liability-scale for binary traits
- SumHer: No individual-level data required, uses GWAS summary statistics

**Typical Usage Examples**:

**HE Regression (Quantitative Traits):**
```bash
nextflow run test_ldak_he.nf -c conf/test_ldak_he.config -profile singularity
```

**PCGC Regression (Binary Traits):**
```bash
nextflow run test_ldak_pcgc.nf -c conf/test_ldak_pcgc.config -profile singularity
```

**GCTA GREML (Gold Standard):**
```bash
nextflow run main.nf \
    --project heritability_study \
    --genotypes_prediction "data/genotypes.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height \
    -profile slurm_singularity
```

**Summary Statistics (SumHer):**
```bash
nextflow run workflows/ldak/ldak_sumher.nf \
    --summary_stats gwas_results.txt \
    --tagfile tagging_file.tagging \
    -profile singularity
```

---

## 3. Genetic Correlation Workflows

**Purpose**: Estimate the genetic correlation (rg) between two traits - shared genetic architecture

| Workflow | Location | Method | Input Required |
|----------|----------|--------|----------------|
| `ldak_sumcors.nf` | `workflows/ldak/` | LDAK SumCors | GWAS summary statistics for 2 traits + LD tagging file |
| `gcta_greml.nf` | `workflows/gcta/` | GCTA bivariate GREML | Individual-level data for 2 traits (same samples) |

**Entry Point**: Not currently integrated in `workflows/nf_gwas.nf` (standalone execution)

**Key Features**:
- SumCors: Works with summary statistics (most common use case)
- Bivariate GREML: Requires individual-level data with both traits measured in same cohort
- Estimates genetic correlation coefficient (rg) ranging from -1 to +1

**Typical Usage**:

**Summary Statistics (SumCors):**
```bash
nextflow run workflows/ldak/ldak_sumcors.nf \
    --trait1_stats trait1_gwas.txt \
    --trait2_stats trait2_gwas.txt \
    --tagfile tagging_file.tagging \
    -profile singularity
```

---

## Analysis Type Selection Guide

| Research Question | Analysis Type | Recommended Workflow |
|-------------------|---------------|----------------------|
| "Which SNPs are associated with disease X?" | Association Analysis | `regenie.nf` (large N) or `gcta_fastgwa.nf` |
| "How much of trait variance is genetic?" | Heritability Estimation | `ldak_he.nf` (fast) or `gcta_greml.nf` (accurate) |
| "Is my case-control study heritable?" | Heritability Estimation | `ldak_pcgc.nf` (liability-scale) |
| "What's h² from public GWAS summary stats?" | Heritability Estimation | `ldak_sumher.nf` |
| "Do traits X and Y share genetic architecture?" | Genetic Correlation | `ldak_sumcors.nf` (summary stats) |
| "Genetic correlation in my cohort?" | Genetic Correlation | `gcta_greml.nf` (bivariate mode) |

---

## Supporting Workflows

**Data Conversion**:
- `modules/local/imputed_to_plink.nf` - VCF to PLINK1 format
- `modules/local/imputed_to_plink2.nf` - VCF to PLINK2 format

**Quality Control**:
- `workflows/ldak/ldak_qc.nf` - Inflation testing via chromosome quartering
- `modules/local/ldak/calc_inflation.nf` - Genomic inflation calculation

---

## Related Documentation

- [Root Documentation](../CLAUDE.md)
- [REGENIE Workflows](../workflows/regenie/CLAUDE.md)
- [GCTA Workflows](../workflows/gcta/CLAUDE.md)
- [LDAK Workflows](../workflows/ldak/CLAUDE.md)
- [BOLT-LMM Workflows](../workflows/bolt_lmm/CLAUDE.md)
