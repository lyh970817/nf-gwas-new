# Local Modules

[Root Directory](../../CLAUDE.md) > **modules/local**

## Change Log (Changelog)

### 2025-12-12 14:21:30
- Initial documentation creation
- Catalogued all process modules across REGENIE, GCTA, LDAK, BOLT-LMM

---

## Module Responsibilities

This directory contains process-level modules (atomic computational tasks) that are composed into workflows. Each module:
- Defines a single Nextflow `process` with explicit inputs/outputs
- Executes a specific bioinformatics tool or script
- Handles resource allocation via labels or direct configuration
- Manages output publishing to results directories

**Module Categories**:
1. **Data Conversion**: VCF to PLINK format conversion
2. **REGENIE**: Two-step GWAS processes
3. **GCTA**: GRM calculation, GREML, FastGWA
4. **LDAK**: Kinship matrices, heritability estimation
5. **BOLT-LMM**: Mixed model processes

---

## Module Index

### Data Conversion Modules

| Module | Input | Output | Tool |
|--------|-------|--------|------|
| `imputed_to_plink.nf` | VCF file | PLINK1 (bed/bim/fam) | plink2 |
| `imputed_to_plink2.nf` | VCF file | PLINK2 (pgen/psam/pvar) | plink2 |
| `plink1_to_plink2.nf` | PLINK1 (bed/bim/fam) | PLINK2 (pgen/psam/pvar) | plink2 |
| `plink2_to_plink1.nf` | PLINK2 (pgen/psam/pvar) | PLINK1 (bed/bim/fam) | plink2 |

### REGENIE Modules (regenie/)

| Module | Purpose | Tool |
|--------|---------|------|
| `regenie_step1_run.nf` | Standard Step 1 execution | regenie |
| `regenie_step1_split.nf` | Split genotypes into chunks | custom |
| `regenie_step1_run_chunk.nf` | Run Step 1 on single chunk | regenie |
| `regenie_step1_merge_chunks.nf` | Merge chunk predictions | regenie |
| `regenie_step2_run.nf` | Single-variant association tests | regenie |
| `regenie_step2_run_gene_tests.nf` | Gene-based tests | regenie |

### GCTA Modules (gcta/)

| Module | Purpose | Tool |
|--------|---------|------|
| `make_grm_part.nf` | Compute GRM partition | gcta |
| `merge_grm_parts.nf` | Merge GRM partitions | gcta |
| `make_mpfiles.nf` | Create multi-part files | gcta |
| `merge_mpfiles.nf` | Merge multi-part files | custom |
| `merge_snp_groups.nf` | Merge SNP group files | custom |
| `make_mgrm.nf` | Create multi-GRM file | custom |
| `adjust_grm.nf` | Adjust GRM for covariates | gcta |
| `remove_related_subjects.nf` | Filter related individuals | gcta |
| `run_reml.nf` | REML variance estimation | gcta |
| `run_fastgwa_mlm.nf` | FastGWA mixed model | gcta |
| `calculate_ld_scores.nf` | LD score calculation | gcta |
| `make_bk_sparse.nf` | Create sparse GRM | gcta |
| `prepare_phenocov.nf` | Format phenotype/covariate files | R script |
| `prepare_phenocov_bivariate.nf` | Format bivariate phenotypes | R script |
| `run_bivariate_reml.nf` | Bivariate REML (single GRM) | gcta |
| `run_bivariate_reml_ldms.nf` | Bivariate REML (multi-GRM) | gcta |

### LDAK Modules (ldak/)

| Module | Purpose | Tool |
|--------|---------|------|
| `calc_kins_uniform.nf` | Uniform kinship matrix | ldak6 |
| `calc_kins_weights.nf` | Weighted kinship matrix | ldak6 |
| `calc_kins_human.nf` | Human-specific kinship | ldak6 |
| `calc_kins_meta.nf` | Meta-analysis kinship | ldak6 |
| `thin_predictors.nf` | LD-based predictor thinning | ldak6 |
| `create_thin_weights.nf` | Create thinning weights | ldak6 |
| `filter_relatedness.nf` | Remove related individuals | ldak6 |
| `add_grms.nf` | Add multiple GRMs | ldak6 |
| `make_mgrm_ldak.nf` | Create multi-GRM file | custom |
| `ldak_reml.nf` | LDAK REML estimation | ldak6 |
| `ldak_he.nf` | Haseman-Elston regression | ldak6 |
| `ldak_pcgc.nf` | PCGC liability-scale heritability | ldak6 |
| `ldak_sumher.nf` | Summary-based heritability | ldak6 |
| `ldak_sumcors.nf` | Summary-based correlations | ldak6 |
| `calc_inflation.nf` | Calculate genomic inflation | R script |
| `calc_genotype_error.nf` | Genotype error estimation | ldak6 |

### BOLT-LMM Modules (bolt_lmm/)

| Module | Purpose | Tool |
|--------|---------|------|
| `run_reml.nf` | BOLT-LMM REML | bolt-lmm |

---

## Process Design Patterns

### Standard Process Template
```groovy
process PROCESS_NAME {
    tag "identifier_${variable}"
    publishDir "${params.pubDir}/output_subdir",
               mode: 'copy',
               pattern: '*.output'

    label 'process_medium'  // or direct cpu/memory spec

    input:
    tuple val(id), path(input_file)

    output:
    path "output_${id}.*", emit: result

    script:
    """
    tool_command \\
        --input ${input_file} \\
        --threads ${task.cpus} \\
        --output output_${id}
    """
}
```

### Resource Allocation Patterns

**Label-based** (from conf/base.config):
```groovy
label 'process_low'      // 2 CPUs, 6 GB RAM (slurm_singularity)
label 'process_medium'   // 6 CPUs, 36 GB RAM
label 'process_high'     // 12 CPUs, 72 GB RAM
```

**Direct specification**:
```groovy
cpus = { 10 * task.attempt }
memory = { 16.GB * task.attempt }
```

### Error Handling
All processes inherit from base.config:
```groovy
errorStrategy = 'retry'
maxRetries = 3
```

---

## Key Dependencies

### Bioinformatics Tools
- **PLINK 1.9** (plink): Legacy PLINK format handling
- **PLINK 2.0** (plink2): Modern VCF processing
- **REGENIE v3.4**: Two-step GWAS
- **GCTA**: GRM and REML methods
- **LDAK6**: LD-adjusted kinship
- **BOLT-LMM**: Mixed model association
- **bedtools**: Genomic interval operations
- **htslib**: VCF/BCF manipulation

### Scripts and Utilities
- **R scripts** (bin/*.R): Statistics and data manipulation
- **Java utilities** (bin/*.java): Log parsing and validation
- **Groovy libraries** (lib/*.groovy): Helper functions

### Configuration
- `conf/base.config`: Process-specific resource definitions
- `nextflow.config`: Global parameters and defaults

---

## Testing and Quality

### Module Testing Strategy
Each critical module has an nf-test file in `tests/modules/local/`:
```
tests/modules/local/
├── regenie_step1.nf.test
├── regenie_step2.nf.test
├── regenie_step2_gene_tests.nf.test
├── imputed_to_plink.nf.test
├── imputed_to_plink2.nf.test
├── gcta_greml.nf.test
└── ...
```

### Running Module Tests
```bash
# Test specific module
nf-test test tests/modules/local/regenie_step1.nf.test

# Update snapshot after intentional changes
nf-test test tests/modules/local/regenie_step1.nf.test --update-snapshot
```

---

## Frequently Asked Questions (FAQ)

**Q: How do I add a new process module?**
A:
1. Create `.nf` file in appropriate subdirectory (e.g., `modules/local/mytool/`)
2. Define process with inputs, outputs, script block
3. Add resource configuration to `conf/base.config` if needed
4. Create test in `tests/modules/local/mytool/`
5. Include in workflow via `include { PROCESS_NAME } from './modules/local/mytool/process.nf'`

**Q: Why separate PLINK1 and PLINK2 conversion?**
A: Some tools (GCTA, BOLT-LMM, LDAK) prefer PLINK1 format, while REGENIE and modern tools use PLINK2. Both are generated in parallel.

**Q: What's the difference between process label and direct resource specification?**
A: Labels enable profile-specific resource allocation (e.g., different values for local vs. SLURM). Direct specification is fixed across profiles.

**Q: How are chromosomes parallelized in processes?**
A: Processes receive chromosome-specific inputs via channels. Nextflow automatically parallelizes across available resources.

**Q: Can I modify tool versions?**
A: Yes, update `environment.yml` and rebuild containers. Ensure compatibility with existing scripts.

---

## Submodule Documentation

- [REGENIE Modules](./regenie/CLAUDE.md)
- [GCTA Modules](./gcta/CLAUDE.md)
- [LDAK Modules](./ldak/CLAUDE.md)
- [BOLT-LMM Modules](./bolt_lmm/CLAUDE.md)

---

## Related File List

### Top-level Conversion Modules
- `imputed_to_plink.nf` - VCF to PLINK1 conversion
- `imputed_to_plink2.nf` - VCF to PLINK2 conversion
- `plink1_to_plink2.nf` - PLINK1 to PLINK2 conversion
- `plink2_to_plink1.nf` - PLINK2 to PLINK1 conversion

### Subdirectories
- `regenie/` - REGENIE process modules (6 files)
- `gcta/` - GCTA process modules (18 files)
- `ldak/` - LDAK process modules (14 files)
- `bolt_lmm/` - BOLT-LMM process modules (1 file + README)
