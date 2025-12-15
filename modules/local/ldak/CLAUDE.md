# LDAK Modules

[Root Directory](../../../CLAUDE.md) > [modules/local](../CLAUDE.md) > **ldak**

## Change Log (Changelog)

### 2025-12-16
- **Added**: `liftover_sumstats.nf` process for genome build conversion (GRCh38 → GRCh37)
- **Added**: `bin/liftover_sumstats.R` script using MungeSumstats::liftover()
- **Updated**: `ldak_sumher.nf` and `ldak_sumcors.nf` workflows to support optional liftover
- **Added**: New parameters: `ldak_sumher_liftover`, `ldak_sumcors_liftover`, etc.

### 2025-12-14
- **Documentation Refactor**: Extracted detailed process descriptions to separate reference files
  - `KINSHIP_REFERENCE.md` - Kinship calculation and GRM management processes
  - `HERITABILITY_REFERENCE.md` - REML, HE, PCGC, SumHer, SumCors processes
  - `QC_REFERENCE.md` - Inflation testing and genotype error estimation
- **Streamlined main CLAUDE.md** (626 → ~250 lines): Now focuses on overview, tables, and FAQs

### 2025-12-13 09:41:58
- Initial documentation creation
- Documented all LDAK process modules for kinship, REML, summary statistics, and QC

---

## Module Responsibilities

LDAK (LD-Adjusted Kinships) process modules implement atomic tasks for LD-aware heritability estimation and association testing. These processes enable:

**Kinship Calculation**:
- Multiple weighting schemes (human_default, uniform, ldak-thin)
- Chromosome-specific and combined kinship matrices
- LD-based predictor thinning

**Heritability Estimation**:
- REML variance component analysis (slow, accurate)
- Haseman-Elston regression (fast, 10-100x faster than REML)
- PCGC regression for binary traits (liability-scale h²)
- Summary statistics-based heritability (SumHer)
- Genetic correlation (SumCors)

**Quality Control**:
- Inflation testing via chromosome quartering
- Genotype error estimation
- Relatedness filtering

**IMPORTANT**: For detailed LDAK methodology, consult the **LDAK skill** documentation.

---

## Module Index

### Kinship Calculation Modules

| Module | Purpose | Weighting Scheme | Key Parameter | Reference |
|--------|---------|------------------|---------------|-----------|
| `calc_kins_human.nf` | Human-specific kinship | LDAK model (power -.25) | `--power -.25` | [→](KINSHIP_REFERENCE.md#calc_kins_human) |
| `calc_kins_uniform.nf` | Uniform weighting | Equal weights | `--power 0` | [→](KINSHIP_REFERENCE.md#calc_kins_uniform) |
| `calc_kins_weights.nf` | Custom weighted kinship | User-provided weights | `--weights <file>` | [→](KINSHIP_REFERENCE.md#calc_kins_weights) |
| `calc_kins_meta.nf` | Meta-analysis kinship | TBD | TBD | [→](KINSHIP_REFERENCE.md#calc_kins_meta) |
| `thin_predictors.nf` | LD-based thinning | Predictor pruning | `--thin` | [→](KINSHIP_REFERENCE.md#thin_predictors) |
| `create_thin_weights.nf` | Generate thinning weights | Weight calculation | Custom script | [→](KINSHIP_REFERENCE.md#create_thin_weights) |

### GRM Management Modules

| Module | Purpose | Input | Output | Reference |
|--------|---------|-------|--------|-----------|
| `add_grms.nf` | Combine multiple kinships | Multiple GRMs | Single combined GRM | [→](KINSHIP_REFERENCE.md#add_grms) |
| `make_mgrm_ldak.nf` | Create multi-GRM file | GRM prefix list | .mgrm file | [→](KINSHIP_REFERENCE.md#make_mgrm_ldak) |
| `filter_relatedness.nf` | Remove related individuals | Kinship matrix | Keep/lose lists | [→](KINSHIP_REFERENCE.md#filter_relatedness) |

### Heritability Estimation Modules

| Module | Purpose | Method | Speed | Output | Reference |
|--------|---------|--------|-------|--------|-----------|
| `ldak_reml.nf` | REML variance estimation | Mixed model | Slow | .reml results | [→](HERITABILITY_REFERENCE.md#ldak_reml) |
| `ldak_he.nf` | Haseman-Elston regression | HE regression | **Fast (10-100x)** | .he results | [→](HERITABILITY_REFERENCE.md#ldak_he) |
| `ldak_pcgc.nf` | Binary trait heritability (liability scale) | PCGC regression | Medium | .pcgc results | [→](HERITABILITY_REFERENCE.md#ldak_pcgc) |
| `ldak_sumher.nf` | Summary statistics heritability | SumHer | Fast | .hers, .enrich | [→](HERITABILITY_REFERENCE.md#ldak_sumher) |
| `ldak_sumcors.nf` | Genetic correlation | SumCors | Fast | .cors results | [→](HERITABILITY_REFERENCE.md#ldak_sumcors) |

### Quality Control Modules

| Module | Purpose | Input | Output | Reference |
|--------|---------|-------|--------|-----------|
| `calc_inflation.nf` | Calculate inflation factor | Full + quarter REML | inflation_results.txt | [→](QC_REFERENCE.md#calc_inflation) |
| `calc_genotype_error.nf` | Estimate genotype errors | Batch data | .he error estimates | [→](QC_REFERENCE.md#calc_genotype_error) |

### Data Processing Modules

| Module | Purpose | Input | Output | Reference |
|--------|---------|-------|--------|-----------|
| `liftover_sumstats.nf` | Convert genome build | Summary stats (GRCh38) | Summary stats (GRCh37) | See below |

#### LIFTOVER_SUMSTATS

**Purpose**: Convert GWAS summary statistics between genome builds using MungeSumstats::liftover()
and apply MAF filtering.

**Inputs**:
- `tuple val(trait_name), path(summary_stats)`: Summary statistics file
- `val target_build`: Target genome build ("GRCh37" or "GRCh38")
- `val source_build`: Source genome build ("GRCh37", "GRCh38", or "auto")
- `val frq_filter`: MAF filter threshold (default: 0.01)

**Outputs**:
- `tuple val(trait_name), path("${trait_name}_lifted.tsv.gz")`: Lifted summary stats
- `path "${trait_name}_liftover.log"`: Log file

**Parameters**:
- `--ldak_sumher_liftover true`: Enable for SumHer workflow
- `--ldak_sumher_target_build 'GRCh37'`: Target build (default: GRCh37)
- `--ldak_sumher_source_build 'auto'`: Source build (default: auto-detect)
- `--ldak_sumher_frq_filter 0.01`: MAF filter threshold (default: 0.01)
- Similar parameters for SumCors: `--ldak_sumcors_liftover`, `--ldak_sumcors_frq_filter`, etc.

**For detailed process descriptions**, see:
- [Kinship Process Reference](KINSHIP_REFERENCE.md)
- [Heritability Process Reference](HERITABILITY_REFERENCE.md)
- [QC Process Reference](QC_REFERENCE.md)

---

## Method Comparison Quick Reference

| Method | Data Required | Speed | Accuracy | Best For |
|--------|--------------|-------|----------|----------|
| **REML** | Individual-level | Slow | Highest | Gold standard, N < 100k |
| **HE Regression** | Individual-level | **10-100x faster** | High (±5%) | N > 100k, QC, screening |
| **PCGC** | Individual-level (binary) | Medium | High | Case-control studies |
| **SumHer** | Summary statistics | Fast | High | No individual data |
| **SumCors** | Summary stats (2 traits) | Fast | High | Genetic correlation |

---

## Testing and Quality

### Expected Outputs
- Kinship values: -1 to 1
- REML h²: 0 to 1 (slightly negative possible)
- Inflation factor: ~4.0 for chromosome quartering (not ~1.0!)
- Genotype error: <1% for high-quality data

### Module Tests
No dedicated LDAK module tests currently. Integration testing via main workflow.

---

## Frequently Asked Questions (FAQ)

### Kinship Calculation

**Q: Which kinship model should I use?**
A: Use `calc_kins_human` (power -.25) for human GWAS. It's the LDAK default and typically most accurate.

**Q: What does power -.25 mean?**
A: Downweights SNPs proportional to (MAF × (1-MAF))^-.25. High-LD SNPs get lower weight. Consult **LDAK skill** for details.

**Q: When should I use ldak-thin model?**
A: For very large datasets or when you want maximum LD-based pruning. It's slower but can improve accuracy.

**Q: How long does kinship calculation take?**
A: O(NM) where N=samples, M=SNPs. Typical: 1-2 hours for 100k samples, 500k SNPs.

**Q: What does filter_relatedness max-rel 0.05 mean?**
A: Removes individuals with kinship > 0.05 (approximately 3rd-degree relatives or closer).

**Q: Why does LDAK give different h² than GCTA?**
A: LDAK downweights high-LD SNPs, reducing inflation. GCTA assumes equal per-SNP heritability.

### Heritability Estimation

**Q: When should I use Haseman-Elston regression instead of REML?**
A: Use HE regression (`--ldak_use_he_regression true`) for:
- Large datasets (N > 100k) where speed is critical
- Initial QC and preliminary heritability screening
- Genotype error estimation
HE is 10-100x faster than REML but slightly less precise (±5% difference). For final h² estimates, use REML.

**Q: What is PCGC regression and when should I use it?**
A: PCGC (Phenotype Correlation-Genotype Correlation) regression estimates heritability on the liability scale for binary traits (case-control studies).
- Use it (`--ldak_run_pcgc true`) instead of standard REML for disease traits
- **Must provide disease prevalence** (`--ldak_pcgc_prevalence`), e.g., 0.05 for 5% prevalence
- Critical for case-control studies to account for ascertainment bias

**Q: Can I use PCGC for quantitative traits?**
A: No, PCGC is specifically designed for binary (case-control) traits. For quantitative traits, use standard REML or HE regression.

**Q: What prevalence value should I use for PCGC?**
A: Use the **population prevalence** of the disease, not the case fraction in your sample. For example, if studying Type 2 Diabetes with ~10% population prevalence, use `--ldak_pcgc_prevalence 0.10`, even if your case-control ratio is 50:50.

**Q: How do I interpret negative heritability?**
A: Slightly negative h² (e.g., -0.05) is sampling variation. Constrain to 0. Large negative values indicate model issues. See [QC Reference](QC_REFERENCE.md#issue-4-negative-heritability) for troubleshooting.

### Summary Statistics

**Q: What tagging files do I need for SumHer?**
A: Download from LDAK website for your population. Use matching ancestry to GWAS summary statistics.

**Q: Can I create my own tagging files?**
A: Yes, use `ldak6 --calc-tagging`. Consult **LDAK skill** for instructions.

**Q: My summary statistics are in GRCh38, but LDAK tagfiles are GRCh37. What do I do?**
A: Enable liftover to convert your summary statistics to GRCh37 before analysis:
```bash
nextflow run main.nf \
    --run_heritability_estimation true \
    --heritability_method ldak_sumher \
    --ldak_sumher_liftover true \
    --ldak_sumher_target_build 'GRCh37' \
    --ldak_sumher_source_build 'auto' \
    ...
```
The pipeline uses MungeSumstats::liftover() for coordinate conversion.

**Q: How many variants are typically lost during liftover?**
A: Usually <5% of variants are lost. Losses >10% may indicate issues with input data or coordinate systems. Check the `*_liftover.log` file for details.

### Quality Control

**Q: What is the inflation factor and how should I interpret it?**
A: For chromosome quartering QC:
- **Expected inflation ≈ 4.0** (full genome vs. quarters)
- inflation > 4.2: Population structure or cryptic relatedness → add covariates
- inflation < 3.8: Over-correction → reduce covariates
See [QC Reference](QC_REFERENCE.md#calc_inflation) for detailed interpretation.

### General

**Q: Where can I find detailed LDAK methodology documentation?**
A: Consult the **LDAK skill** for comprehensive documentation covering all LDAK methods, theory, and usage.

---

## Process Files Summary

**Kinship Calculation**: 6 processes
- `calc_kins_human.nf`, `calc_kins_uniform.nf`, `calc_kins_weights.nf`, `calc_kins_meta.nf`
- `thin_predictors.nf`, `create_thin_weights.nf`

**GRM Management**: 3 processes
- `add_grms.nf`, `make_mgrm_ldak.nf`, `filter_relatedness.nf`

**Heritability**: 5 processes
- `ldak_reml.nf`, `ldak_he.nf`, `ldak_pcgc.nf`
- `ldak_sumher.nf`, `ldak_sumcors.nf`

**Quality Control**: 2 processes
- `calc_inflation.nf`, `calc_genotype_error.nf`

**Data Processing**: 1 process
- `liftover_sumstats.nf` - Genome build conversion using MungeSumstats

**Total**: 17 process modules

---

## Related Documentation

### Within LDAK Modules
- **[Kinship Process Reference](KINSHIP_REFERENCE.md)** - Detailed kinship calculation and GRM management
- **[Heritability Process Reference](HERITABILITY_REFERENCE.md)** - REML, HE, PCGC, SumHer, SumCors details
- **[QC Process Reference](QC_REFERENCE.md)** - Inflation testing and genotype error estimation

### Pipeline Documentation
- [LDAK Workflows](../../../workflows/ldak/CLAUDE.md) - Workflow orchestration
- [Modules Overview](../CLAUDE.md) - All module categories
- [Root Documentation](../../../CLAUDE.md) - Pipeline overview
- [LDAK Integration Guide](../../../CLAUDE.md#ldak-integration-in-nf-gwas) - Parameters and usage

### External
- **LDAK Skill** - Comprehensive LDAK methodology and theory documentation
- [LDAK Website](https://dougspeed.com) - Official LDAK software and resources
