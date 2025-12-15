# Workflows Module

[Root Directory](../CLAUDE.md) > **workflows**

## Change Log (Changelog)

### 2025-12-13
- Added LDAK HE and PCGC regression workflows to documentation
- Updated Submodule Index to reflect all workflows including commented ones
- Updated Related File List with complete workflow inventory

### 2025-12-12 14:21:30
- Initial documentation creation
- Documented all workflow subdirectories and orchestration patterns

---

## Module Responsibilities

This directory contains the high-level workflow orchestration logic for the nf-gwas pipeline. Workflows compose multiple processes from `modules/local/` into complete analysis pipelines.

**Key Responsibilities:**
- Orchestrate multi-step analysis workflows (REGENIE, GCTA, LDAK, BOLT-LMM)
- Define data flow between processes via Nextflow channels
- Handle conditional logic (e.g., gene-based tests, interaction tests)
- Coordinate parallel execution across chromosomes/chunks
- Emit final results to downstream consumers

---

## Entry and Startup

**Primary Workflow Entry**: `nf_gwas.nf`
- Called from `main.nf` via `include { NF_GWAS } from './workflows/nf_gwas'`
- Orchestrates all analysis pathways based on user parameters
- Currently configured to run LDAK_QC workflow (lines 136-140)

**Workflow Hierarchy:**
```
nf_gwas.nf (main orchestrator)
├── IMPUTED_TO_PLINK / IMPUTED_TO_PLINK2 (VCF conversion)
├── LDAK_QC (quality control and inflation testing)
├── GCTA_GREML_LDMS (commented out - GREML with LD scores)
├── GCTA_FASTGWA (commented out - FastGWA mixed model)
├── BOLT_LMM_REML (commented out - BOLT-LMM analysis)
└── SINGLE_VARIANT_TESTS (commented out - REGENIE-based tests)
    └── REGENIE (regenie.nf)
        ├── REGENIE_STEP1 (whole genome regression)
        └── REGENIE_STEP2 (association testing)
```

---

## External Interfaces

### Input Channels
From `nf_gwas.nf`:
- `imputed_files_ch`: VCF files for association testing (sorted by chromosome)
- `genotyped_plink_ch`: PLINK files for prediction (optional, can be empty if skip_predictions=true)
- `phenotypes_file`: Phenotype data
- `covariates_file`: Covariate data (optional)
- `condition_list_file`: Conditional SNP list (optional)

### Output Channels
Emitted from `nf_gwas.nf`:
- `ldak_qc_quarter_reml`: REML results from chromosome quarters
- `ldak_qc_inflation`: Inflation statistics
- `ldak_qc_genotype_error`: Genotype error estimates (if batch parameters set)

### Workflow Calling Convention
```groovy
include { WORKFLOW_NAME } from './path/to/workflow.nf'

WORKFLOW_NAME (
    input_channel_1,
    input_file_2,
    parameter_value_3
)

results_ch = WORKFLOW_NAME.out.result_name
```

---

## Key Dependencies and Configuration

### Internal Dependencies
- `modules/local/imputed_to_plink.nf`: VCF to PLINK1 conversion
- `modules/local/imputed_to_plink2.nf`: VCF to PLINK2 conversion
- All workflow-specific process modules (in respective subdirectories)

### Configuration Parameters
From `params`:
- `params.genotypes_association`: Glob pattern for VCF files
- `params.genotypes_prediction`: PLINK file pattern
- `params.phenotypes_filename`: Phenotype file path
- `params.covariates_filename`: Covariate file path (optional)
- `params.regenie_skip_predictions`: Skip Step 1 flag
- `params.nparts_gcta`: GRM calculation parallelization

---

## Data Models

### Channel Structure Patterns

**Imputed PLINK Channel** (from IMPUTED_TO_PLINK):
```groovy
[chr_num, filename, bed, bim, fam, range]
// Example: [1, "chr01", chr01.bed, chr01.bim, chr01.fam, null]
```

**Genotyped PLINK Channel**:
```groovy
[filename_base, [bed, bim, fam]]
// Example: ["example", [example.bed, example.bim, example.fam]]
```

**REGENIE Step 1 Output**:
```groovy
[prediction files, loco files, log file]
```

**REGENIE Step 2 Output**:
```groovy
[phenotype, chromosome, result_file]
```

---

## Testing and Quality

### Workflow Tests
- `tests/main.nf.test`: Integration test for full pipeline
- Individual workflow tests in respective subdirectories

### Test Invocation
```bash
# Test main workflow with test profile
nextflow run main.nf -profile test,singularity

# nf-test for specific workflow
nf-test test tests/main.nf.test
```

---

## Submodule Index

| Submodule | Description | Entry Points | Status |
|-----------|-------------|-------------|--------|
| `regenie/` | REGENIE two-step GWAS | `regenie.nf`, `regenie_step1.nf`, `regenie_step2.nf` | Active (commented in nf_gwas) |
| `gcta/` | GCTA GRM and GREML workflows | `gcta_grm.nf`, `gcta_greml.nf`, `gcta_greml_ldms.nf`, `gcta_fastgwa.nf` | Active (partially commented) |
| `ldak/` | LDAK kinship and heritability workflows | `ldak.nf`, `ldak_qc.nf`, `calc_kins.nf`, `ldak_he.nf`, `ldak_pcgc.nf`, `ldak_sumher.nf`, `ldak_sumcors.nf` | Active (LDAK_QC currently used) |
| `bolt_lmm/` | BOLT-LMM mixed models | `bolt_lmm_reml.nf` | Active (commented in nf_gwas) |
| `single_variant_tests.nf` | Orchestrates REGENIE for single-variant tests | `single_variant_tests.nf` | Active (commented in nf_gwas) |

See individual submodule CLAUDE.md files for detailed documentation.

---

## Frequently Asked Questions (FAQ)

**Q: Why are many workflows commented out in nf_gwas.nf?**
A: The pipeline is currently configured to run only LDAK_QC. Other workflows can be enabled by uncommenting the respective sections and adjusting output emissions.

**Q: How do I add a new workflow?**
A:
1. Create workflow file in appropriate subdirectory (e.g., `workflows/mytool/mytool.nf`)
2. Define inputs/outputs following DSL2 patterns
3. Include and call from `nf_gwas.nf`
4. Add output channel to `emit:` block
5. Create tests in `tests/workflows/mytool/`

**Q: What's the difference between workflow and process?**
A: Workflows orchestrate multiple processes. Processes execute single computational tasks. Workflows are in `workflows/`, processes are in `modules/local/`.

**Q: How are chromosomes parallelized?**
A: VCF files are sorted and assigned sequential chromosome numbers via `.withIndex()`. Processes receive chromosome-specific data via channels, enabling automatic parallelization.

---

## Related File List

### Core Workflow Files
- `nf_gwas.nf` - Main workflow orchestrator
- `single_variant_tests.nf` - Single-variant test coordination

### Submodule Workflows

**REGENIE Workflows:**
- `regenie/regenie.nf` - REGENIE entry point
- `regenie/regenie_step1.nf` - Step 1 workflow (whole genome regression)
- `regenie/regenie_step2.nf` - Step 2 workflow (association testing)

**GCTA Workflows:**
- `gcta/gcta_grm.nf` - GRM calculation
- `gcta/gcta_greml.nf` - GREML analysis
- `gcta/gcta_greml_ldms.nf` - GREML with LD scores
- `gcta/gcta_fastgwa.nf` - FastGWA workflow

**LDAK Workflows:**
- `ldak/ldak.nf` - Main LDAK workflow (kinship + REML)
- `ldak/ldak_qc.nf` - QC and inflation testing
- `ldak/calc_kins.nf` - Kinship calculation (subworkflow)
- `ldak/ldak_he.nf` - Haseman-Elston regression (fast heritability)
- `ldak/ldak_pcgc.nf` - PCGC regression (binary trait heritability)
- `ldak/ldak_sumher.nf` - SumHer heritability (summary stats)
- `ldak/ldak_sumcors.nf` - SumCors genetic correlation (summary stats)

**BOLT-LMM Workflows:**
- `bolt_lmm/bolt_lmm_reml.nf` - BOLT-LMM REML
