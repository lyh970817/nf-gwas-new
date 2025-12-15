# LDAK Workflows

[Root Directory](../../CLAUDE.md) > [workflows](../CLAUDE.md) > **ldak**

## Change Log (Changelog)

### 2025-12-13 09:41:58
- Initial documentation creation
- Documented LDAK kinship, QC, SumHer, and SumCors workflows
- Added LDAK documentation reference guidelines

---

## Module Responsibilities

LDAK (LD-Adjusted Kinships) workflows implement heritability estimation and association testing methods that account for linkage disequilibrium patterns. The workflows support:

1. **LDAK_REML**: Individual-level kinship calculation and REML heritability
2. **LDAK_QC**: Quality control testing for inflation and genotype error
3. **CALC_KINS**: Conditional kinship calculation based on heritability models
4. **LDAK_SUMHER**: Summary statistics-based heritability estimation
5. **LDAK_SUMCORS**: Genetic correlation estimation from summary statistics

**Key Features**:
- LD-aware weighting schemes (human_default, uniform, ldak-thin)
- Inflation testing via chromosome quartering
- Summary statistics analysis (no individual-level data required)
- Genotype error estimation
- Multi-component kinship models

**IMPORTANT**: For detailed LDAK methodology and parameter specifications, always consult `docs/external/ldak/_manifest.md` first, then refer to specific documentation files.

---

## Entry and Startup

### Primary Workflows

**1. LDAK_REML** (`ldak_reml.nf`)
- Main individual-level LDAK workflow
- Calculates kinship matrices with LD weighting
- Runs REML heritability estimation
- Filters related individuals

**2. LDAK_QC** (`ldak_qc.nf`)
- Quality control and inflation testing
- Divides chromosomes into quarters
- Calculates inflation statistics
- Optional genotype error estimation

**3. CALC_KINS** (`calc_kins.nf`)
- Conditional kinship calculation
- Supports multiple heritability models
- Subworkflow used by LDAK_REML and LDAK_QC

**4. LDAK_SUMHER_WORKFLOW** (`ldak_sumher.nf`)
- Summary statistics heritability estimation
- Requires pre-computed tagging files
- No individual-level data needed

**5. LDAK_SUMCORS_WORKFLOW** (`ldak_sumcors.nf`)
- Genetic correlation between traits
- Summary statistics-based
- Requires pre-computed tagging files

**6. LDAK_HE_WORKFLOW** (`ldak_he.nf`)
- Haseman-Elston regression for heritability
- Faster alternative to REML (10-100x speedup)
- Less precise but useful for large datasets (N > 100k)
- Ideal for initial QC and genotype error estimation

**7. LDAK_PCGC_WORKFLOW** (`ldak_pcgc.nf`)
- PCGC regression for binary traits
- Liability-scale heritability estimation
- Critical for case-control studies
- Requires disease prevalence parameter

### Invocation Pattern
```groovy
include { LDAK_QC } from './workflows/ldak/ldak_qc'

LDAK_QC(
    imputed_plink_ch,
    phenotype_file,
    covariates_file
)
```

---

## External Interfaces

### Input Channels

**LDAK_REML**:
- `imputed_plink_ch`: PLINK files `[chr_num, filename, bed, bim, fam, range]`
- `phenotype_file`: Path to phenotype file
- `covariates_file`: Path to covariate file (optional)
- `heritability_model`: Model type (human_default/uniform/ldak-thin)

**LDAK_QC**:
- `imputed_plink_ch`: PLINK files
- `phenotype_file`: Phenotype file path
- `covariates_file`: Covariate file path

**CALC_KINS**:
- `imputed_plink_ch`: PLINK files
- `heritability_model`: Model selection parameter

**LDAK_SUMHER_WORKFLOW**:
- `summary_stats_ch`: Tuple `[trait_name, summary_stats_file]`
- `tagfile`: Path to pre-computed tagging file

**LDAK_SUMCORS_WORKFLOW**:
- `summary_stats_pairs_ch`: Tuple `[trait1_name, stats1, trait2_name, stats2]`
- `tagfile`: Path to pre-computed tagging file

**LDAK_HE_WORKFLOW**:
- `imputed_plink_ch`: PLINK files `[chr_num, filename, bed, bim, fam, range]`
- `phenotype_file`: Path to phenotype file
- `covariates_file`: Path to covariate file (optional)
- `heritability_model`: Model type (human_default/uniform/ldak-thin)

**LDAK_PCGC_WORKFLOW**:
- `imputed_plink_ch`: PLINK files `[chr_num, filename, bed, bim, fam, range]`
- `phenotype_file`: Path to binary phenotype file (case/control)
- `covariates_file`: Path to covariate file (optional)
- `heritability_model`: Model type (human_default/uniform/ldak-thin)

### Output Channels

**LDAK_REML**:
- `ldak_grm`: Per-chromosome kinship matrices
- `mgrm_file`: Multi-GRM file list
- `combined_grm`: Combined kinship matrix across chromosomes
- `filtered_list`: List of unrelated individuals
- `reml_results`: REML heritability estimates

**LDAK_QC**:
- `quarter_reml_results`: REML results for chromosome quarters
- `inflation_results`: Inflation statistics
- `genotype_error_results`: Genotype error estimates (if batch params set)

**CALC_KINS**:
- `ldak_grm`: Kinship matrices per chromosome

**LDAK_SUMHER_WORKFLOW**:
- `heritability_results`: *.hers files
- `enrichment_results`: *.enrich files

**LDAK_SUMCORS_WORKFLOW**:
- `correlation_results`: Genetic correlation estimates

**LDAK_HE_WORKFLOW**:
- `ldak_grm`: Per-chromosome kinship matrices
- `combined_grm`: Combined kinship matrix across chromosomes
- `filtered_list`: List of unrelated individuals
- `he_results`: Haseman-Elston heritability estimates

**LDAK_PCGC_WORKFLOW**:
- `ldak_grm`: Per-chromosome kinship matrices
- `combined_grm`: Combined kinship matrix across chromosomes
- `filtered_list`: List of unrelated individuals
- `pcgc_results`: PCGC liability-scale heritability estimates

---

## Key Dependencies and Configuration

### Process Dependencies

**LDAK_REML uses**:
- `workflows/ldak/calc_kins.nf`: Kinship calculation subworkflow
- `modules/local/ldak/make_mgrm_ldak.nf`: Create multi-GRM file
- `modules/local/ldak/add_grms.nf`: Combine kinship matrices
- `modules/local/ldak/filter_relatedness.nf`: Remove related individuals
- `modules/local/ldak/ldak_reml.nf`: REML heritability estimation
- `modules/local/gcta/prepare_phenocov.nf`: Format phenotype/covariate files

**CALC_KINS branches to**:
- `modules/local/ldak/calc_kins_human.nf`: Human default model (power -.25)
- `modules/local/ldak/calc_kins_uniform.nf`: Uniform weighting
- `modules/local/ldak/calc_kins_weights.nf`: Custom weights from thinning
- `modules/local/ldak/thin_predictors.nf`: LD-based predictor thinning
- `modules/local/ldak/create_thin_weights.nf`: Generate thinning weights

**LDAK_QC adds**:
- `modules/local/ldak/calc_inflation.nf`: Calculate inflation statistics
- `workflows/ldak/calc_genotype_error.nf`: Estimate genotype errors (workflow)

### Configuration Parameters

**Heritability Models**:
- `params.heritability_model`: Model selection
  - `human_default`: LDAK model with power -.25 (recommended for human data)
  - `uniform`: Equal weighting across SNPs
  - `ldak-thin`: LD-based thinning approach
  - Default: `human_default` if null

**REML Parameters**:
- `params.phenotypes_filename`: Phenotype file path
- `params.covariates_filename`: Covariate file path
- `params.covariates_columns`: Quantitative covariate names
- `params.covariates_cat_columns`: Categorical covariate names

**QC Parameters**:
- `params.batch_subset_prefix`: Batch identifier prefix (for genotype error)
- `params.batch_subset_number`: Number of batches (for genotype error)

**SumHer Parameters**:
- `params.ldak_sumher_check_sums`: Validate summary statistics (default: true)
- `params.ldak_sumher_prevalence`: Disease prevalence (for case-control)
- `params.ldak_sumher_cutoff`: MAF cutoff

### Tool Requirements
- **LDAK6**: Kinship calculation, REML, SumHer, SumCors
- **R with data.table**: Inflation calculation (`bin/calc_inflation.R`)

---

## Data Models

### Kinship Matrix File Structure
```
chr01.grm.bin       # Binary kinship values
chr01.grm.id        # Individual IDs (FID IID)
chr01.grm.details   # Metadata (SNP count, etc.)
chr01.grm.adjust    # Adjustment factors
```

**Channel Format**: `[chr_num, filename, grm_bin, grm_id, grm_details, grm_adjust]`

### Combined GRM Structure
```
ldak_grm.grm.bin       # Combined kinship across chromosomes
ldak_grm.grm.id        # Individual IDs
ldak_grm.grm.details   # Combined metadata
ldak_grm.grm.adjust    # Combined adjustments
```

### REML Output Structure
```
reml_ldak_grm.reml     # Main REML results
# Contains: Her_ALL, Her_SE, Coefficient estimates, logL

reml_ldak_grm.coeff    # Coefficient estimates
reml_ldak_grm.progress # Iteration progress
reml_ldak_grm.share    # Shared variance components
```

### Inflation Results Structure
```
inflation_results.txt
# Columns: phenotype, h2_full, h2_quarter_mean, inflation_factor
```

### SumHer Output Structure
```
trait.hers             # Heritability estimates
# Contains: Her_ALL, Component_1, Component_2, ...

trait.enrich           # Enrichment statistics (optional)
```

---

## Workflow Logic Details

### LDAK_REML Main Workflow Pipeline
```
1. CALC_KINS: Calculate kinship per chromosome
   → chr01.grm.*, chr02.grm.*, ...

2. MAKE_MGRM_LDAK: Create multi-GRM file
   → ldak_grm.mgrm (list of GRM prefixes)

3. ADD_GRMS: Combine all chromosome GRMs
   → ldak_grm.grm.* (combined)

4. FILTER_RELATEDNESS: Remove related individuals
   → filtered.keep, filtered.lose

5. PREPARE_PHENOCOV: Format phenotype/covariate files
   → phenotypes_noheader.txt, covariates_quant_noheader.txt

6. LDAK_REML: Run REML analysis
   → reml_ldak_grm.reml
```

### LDAK_QC Inflation Testing Pipeline
```
1. Group chromosomes into quarters
   - 4+ chromosomes → 4 quarters
   - 3 chromosomes → 3 groups
   - 2 chromosomes → 2 groups
   - 1 chromosome → no division

2. CALC_KINS: Calculate kinship for each chromosome
   → quarter1_chr1.grm.*, quarter1_chr2.grm.*, ...

3. For multi-chromosome quarters:
   - MAKE_MGRM_LDAK: Create multi-GRM file
   - ADD_GRMS: Combine GRMs within quarter

4. LDAK (full): Calculate full-data heritability
   → reml_ldak_grm.reml

5. LDAK_REML (per quarter): Calculate quarter-specific h2
   → reml_quarter1.reml, reml_quarter2.reml, ...

6. CALC_INFLATION: Compare full vs quarter h2
   → inflation_results.txt
   - inflation_factor = h2_full / mean(h2_quarters)
   - Values > 1 indicate inflation from structure/relatedness

7. CALC_GENOTYPE_ERROR (optional): Estimate batch effects
   → genotype_error.he
```

### CALC_KINS Model Selection
```groovy
if (heritability_model == 'human_default') {
    CALC_KINS_HUMAN(imputed_plink_ch)
    // Uses: ldak6 --calc-kins-direct --power -.25 --ignore-weights YES

} else if (heritability_model == 'uniform') {
    CALC_KINS_UNIFORM(imputed_plink_ch)
    // Uses: ldak6 --calc-kins-direct --power 0

} else if (heritability_model == 'ldak-thin') {
    THIN_PREDICTORS(imputed_plink_ch)
    CREATE_THIN_WEIGHTS(thin_predictors)
    CALC_KINS_WEIGHTS(imputed_plink_ch, thin_weights)
    // Uses: ldak6 --calc-kins-direct --weights <weights_file>

} else {
    // Default to human_default
}
```

---

## Testing and Quality

### Module Tests
No dedicated LDAK workflow tests currently exist. Testing is done via:
- Integration testing in `tests/main.nf.test`
- Process-level tests for individual modules

### Expected Behavior
- Kinship values should be between -1 and 1
- REML h2 estimates should be between 0 and 1 (or slightly negative due to sampling)
- Inflation factor close to 1 indicates no population structure
- Inflation factor > 1.05 suggests inadequate control for structure

---

## Usage Examples

### Standard LDAK REML Heritability
```groovy
LDAK_REML(
    imputed_plink_ch,
    file("phenotypes.txt"),
    file("covariates.txt"),
    "human_default"
)
```

### Quality Control with Inflation Testing
```groovy
LDAK_QC(
    imputed_plink_ch,
    file("phenotypes.txt"),
    file("covariates.txt")
)

// Check inflation_results.txt
// If inflation > 1.05, consider additional PC covariates
```

### Summary Statistics Heritability
```groovy
summary_stats_ch = Channel.of(
    ["BMI", file("bmi_gwas.txt")],
    ["Height", file("height_gwas.txt")]
)

LDAK_SUMHER_WORKFLOW(
    summary_stats_ch,
    file("tagfile_bld_gbr.tagging")
)
```

### Genetic Correlation
```groovy
trait_pairs_ch = Channel.of(
    ["BMI", file("bmi_gwas.txt"), "Height", file("height_gwas.txt")]
)

LDAK_SUMCORS_WORKFLOW(
    trait_pairs_ch,
    file("tagfile_bld_gbr.tagging")
)
```

### Haseman-Elston Regression (Fast Heritability)
```groovy
// For large datasets (N > 100k) where speed is critical
LDAK_HE_WORKFLOW(
    imputed_plink_ch,
    file("phenotypes.txt"),
    file("covariates.txt"),
    "human_default"
)

// Or use parameter to switch from REML to HE
// In nextflow.config or command line:
// --ldak_use_he_regression true
```

### PCGC Regression (Binary Traits)
```groovy
// For case-control studies (disease traits)
// CRITICAL: Must set prevalence parameter
LDAK_PCGC_WORKFLOW(
    imputed_plink_ch,
    file("case_control_phenotypes.txt"),  // Binary: 0/1 or 1/2
    file("covariates.txt"),
    "human_default"
)

// In nextflow.config or command line:
// --ldak_run_pcgc true
// --ldak_pcgc_prevalence 0.05  // 5% disease prevalence
```

---

## Frequently Asked Questions (FAQ)

**Q: Which heritability model should I use?**
A: Use `human_default` for human GWAS data. It accounts for LD structure and typically gives the most accurate estimates. See `docs/external/ldak/` for detailed model comparisons.

**Q: What does inflation factor mean in LDAK_QC?**
A: Inflation = h2_full / mean(h2_quarters). If quarters give similar h2 as full data, inflation ≈ 1 (good). High inflation suggests population structure or relatedness not fully captured.

**Q: How do I interpret negative heritability?**
A: Slightly negative h2 (e.g., -0.05) can occur due to sampling variation. Biologically constrain to 0. Large negative values indicate model misspecification.

**Q: When should I use Haseman-Elston regression instead of REML?**
A: Use HE regression (`--ldak_use_he_regression true`) for large datasets (N > 100k) where speed is critical. HE is 10-100x faster than REML but less precise. It's ideal for initial QC, genotype error estimation, or preliminary heritability screening. For final h² estimates, use REML.

**Q: Can I use LDAK with binary traits?**
A: Yes! For individual-level data, use PCGC regression (`--ldak_run_pcgc true` with `--ldak_pcgc_prevalence`). For summary statistics, use SumHer with `--prevalence` parameter. Both methods estimate liability-scale heritability for case-control studies.

**Q: What is PCGC regression and when should I use it?**
A: PCGC (Phenotype Correlation-Genotype Correlation) regression estimates heritability on the liability scale for binary traits. Use LDAK_PCGC_WORKFLOW or `--ldak_run_pcgc true` for case-control studies. You must provide disease prevalence (`--ldak_pcgc_prevalence`), e.g., 0.05 for 5% prevalence. This is more accurate than standard REML for binary phenotypes.

**Q: What prevalence value should I use for PCGC?**
A: Use the population prevalence of the disease, not the case fraction in your sample. For example, if studying Type 2 Diabetes with ~10% population prevalence, use `--ldak_pcgc_prevalence 0.10`, even if your case-control ratio is 50:50.

**Q: What are tagging files for SumHer/SumCors?**
A: Pre-computed files capturing LD structure. Download from LDAK website or generate using `ldak6 --calc-tagging`. See `docs/external/ldak/32_sumher.md` for details.

**Q: Why does LDAK give different h2 than GCTA?**
A: LDAK downweights high-LD SNPs, reducing inflation from tagging. GCTA assumes equal per-SNP heritability. LDAK is often more accurate for complex traits.

**Q: How many chromosomes do I need for QC inflation testing?**
A: Minimum 2, but 4+ recommended for robust quarter-based estimates.

**Q: What batch_subset parameters are needed for genotype error?**
A: Set `--batch_subset_prefix` (e.g., "Batch_") and `--batch_subset_number` (e.g., 10). LDAK will estimate error rates across batches.

**Q: Where can I find detailed LDAK documentation?**
A: Check `docs/external/ldak/_manifest.md` for navigation, then consult specific methodology files (e.g., `03_calc-kins.md` for kinship calculation).

---

## Workflow Files

- `ldak_reml.nf`: Main LDAK REML workflow (89 lines)
- `ldak_qc.nf`: Quality control and inflation testing (187 lines)
- `calc_kins.nf`: Conditional kinship calculation (52 lines)
- `ldak_he.nf`: Haseman-Elston regression workflow (97 lines)
- `ldak_pcgc.nf`: PCGC binary trait heritability workflow (103 lines)
- `ldak_sumher.nf`: Summary heritability workflow (28 lines)
- `ldak_sumcors.nf`: Genetic correlation workflow (27 lines)

---

## Related Documentation

- [LDAK Modules](../../modules/local/ldak/CLAUDE.md)
- [Root Documentation](../../CLAUDE.md)
- [Workflows Overview](../CLAUDE.md)
- **[LDAK Official Documentation](../../docs/external/ldak/_manifest.md)** (52+ pages)
- [LDAK Website](https://dougspeed.com)
