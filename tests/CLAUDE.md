# Testing Framework (tests/)

[Root Directory](../CLAUDE.md) > **tests**

> **⚠️ QUICK START**: All nf-test commands MUST include `--profile test,singularity`
>
> Example: `nf-test test tests/modules/local/gcta/run_reml.nf.test --profile test,singularity`

---

## Module Responsibilities

The `tests/` directory provides comprehensive testing infrastructure for the nf-gwas pipeline:

1. **Module-level Tests**: Unit tests for individual processes
2. **Workflow-level Tests**: Integration tests for complete workflows
3. **Test Data**: Minimal datasets for rapid validation
4. **Snapshot Testing**: Expected output validation via snapshots

**Testing Framework**: nf-test (Nextflow native testing tool)

---

## Development Prerequisites

### Context7 Integration
**REQUIRED**: When writing or modifying tests, Claude must use Context7 to retrieve up-to-date documentation and best practices for:
- nf-test framework syntax and features
- Nextflow channel operations and testing patterns
- Test assertion methods and snapshot testing
- Process input/output structure validation

This ensures tests follow current nf-test standards and Nextflow DSL2 conventions.

---

## Directory Structure

```
tests/
├── main.nf.test               # Full pipeline integration test
├── nextflow.config            # Test-specific config
├── test-gwas-*.conf           # Test profile configurations
├── modules/local/             # Module-level unit tests
│   ├── regenie/               # REGENIE module tests
│   │   ├── regenie_step1.nf.test
│   │   ├── regenie_step1_split.nf.test
│   │   ├── regenie_step1_run_chunk.nf.test
│   │   ├── regenie_step1_merge_chunks.nf.test
│   │   └── regenie_step2.nf.test
│   ├── gcta/                      # GCTA module tests
│   │   ├── make_grm_part.nf.test
│   │   ├── merge_grm_parts.nf.test
│   │   ├── make_mpfiles.nf.test
│   │   ├── merge-mpfiles.nf.test
│   │   ├── make_mgrm.nf.test
│   │   ├── adjust_grm.nf.test
│   │   ├── remove_related_subjects.nf.test
│   │   ├── run_reml.nf.test
│   │   ├── run_fastgwa_mlm.nf.test
│   │   ├── calculate_ld_scores.nf.test
│   │   ├── make_bk_sparse.nf.test
│   │   ├── merge_snp_groups.nf.test
│   │   └── gcta_greml.nf.test
│   ├── ldak/                  # LDAK module tests
│   │   ├── calc_kins_uniform.nf.test
│   │   ├── calc_kins_weights.nf.test
│   │   ├── calc_kins_human.nf.test
│   │   ├── calc_kins_meta.nf.test
│   │   ├── thin_predictors.nf.test
│   │   ├── create_thin_weights.nf.test
│   │   ├── filter_relatedness.nf.test
│   │   ├── add_grms.nf.test
│   │   ├── make_mgrm_ldak.nf.test
│   │   ├── ldak_reml.nf.test
│   │   ├── ldak_he.nf.test
│   │   ├── ldak_pcgc.nf.test
│   │   ├── ldak_sumher.nf.test
│   │   ├── ldak_sumcors.nf.test
│   │   ├── calc_inflation.nf.test
│   │   └── calc_genotype_error.nf.test
│   ├── bolt_lmm/              # BOLT-LMM module tests
│   │   └── run_reml.nf.test
│   ├── imputed_to_plink.nf.test
│   └── imputed_to_plink2.nf.test
├── workflows/                 # Workflow-level tests
│   ├── gcta/
│   │   ├── gcta_grm.nf.test
│   │   ├── gcta_greml.nf.test
│   │   ├── gcta_greml_ldms.nf.test
│   │   └── gcta_fastgwa.nf.test
│   └── ldak/
│       ├── ldak_qc.nf.test
│       ├── ldak_he.nf.test
│       └── ldak_pcgc.nf.test
└── input/                     # Test data (all files at this level)
    ├── example.{bed,bim,fam}      # Base genotyped data (500 samples)
    ├── chr01.vcf.gz               # Imputed VCF chr1
    ├── chr02.vcf.gz               # Imputed VCF chr2
    ├── chr01.vcf.{bed,bim,fam}    # PLINK1 from chr01 VCF
    ├── chr02.vcf.{bed,bim,fam}    # PLINK1 from chr02 VCF
    ├── phenotype*.txt             # Phenotype files (various formats)
    ├── covariates*.txt            # Covariate files (various formats)
    ├── test_batch1, test_batch2, test_batch3  # Batch test files
    ├── gcta/                      # GCTA-specific test data
    │   ├── README.md              # GCTA test data documentation
    │   ├── gcta_grm.mpfile
    │   ├── gcta_grm.mgrm
    │   ├── batch_grm.mgrm
    │   ├── chr*.mpfile
    │   ├── phenotype*.txt
    │   ├── covariates*.txt
    │   ├── calculate_ld_scores/   # LD score calculation outputs
    │   │   ├── chr01.vcf_gcta_ld.score.ld
    │   │   ├── chr02.vcf_gcta_ld.score.ld
    │   │   ├── chr01.vcf_snp_group*.txt  (4 files)
    │   │   ├── chr02.vcf_snp_group*.txt  (4 files)
    │   │   └── chr*.vcf_gcta_ld.log
    │   ├── merge_snp_groups/      # Merged SNP groups
    │   │   ├── README.md
    │   │   ├── snp_group1.txt
    │   │   └── snp_group3.txt
    │   ├── make_grm_part/         # GRM partition calculation outputs
    │   ├── merge_grm_parts/       # Merged GRM partition outputs
    │   ├── adjust_grm/            # Adjusted GRM outputs
    │   │   ├── README.md
    │   │   ├── gcta_grm_0_adj.*
    │   │   └── gcta_grm_1_adj.*
    │   └── remove_related_subjects/  # Filtered GRM (unrelated subset)
    │       ├── README.md
    │       └── gcta_grm_0_unrel05.*
    ├── ldak/                      # LDAK-specific test data
    ├── bolt_lmm/                  # BOLT-LMM-specific test data
    └── regenie/                   # REGENIE-specific test data
```

---

## Entry and Startup

### Running Tests

> **⚠️ CRITICAL REQUIREMENT**: **ALWAYS** use `--profile test,singularity` when running nf-test commands.
>
> **Why this is mandatory:**
> - Test data paths are correctly resolved
> - Singularity containerization ensures reproducibility
> - Test-specific parameters are applied from `conf/test.config`
> - Without this profile, tests will fail or produce incorrect results
>
> **Format**: `nf-test test <test-file> --profile test,singularity`

```bash
# Run all tests with proper profile
nf-test test --profile test,singularity

# Run specific test file
nf-test test tests/main.nf.test --profile test,singularity

# Run module-level test
nf-test test tests/modules/local/regenie/regenie_step1.nf.test --profile test,singularity

# Run specific tool tests
nf-test test tests/modules/local/gcta/ --profile test,singularity
nf-test test tests/modules/local/ldak/ --profile test,singularity

# Update snapshots after intentional changes
nf-test test --update-snapshot --profile test,singularity

# Verbose output
nf-test test --verbose --profile test,singularity
```

### Test Execution Flow
1. nf-test reads `*.nf.test` files
2. Executes defined test cases with specified inputs
3. Compares outputs to snapshots (`.nf.test.snap` files)
4. Reports pass/fail status

---

## External Interfaces

### Test Data Inputs

**Genotyped Data** (`tests/input/`):
- `example.{bed,bim,fam}`: 500 samples, ~1000 variants, PLINK1 format
- Used for REGENIE Step 1, QC processes, and as base genotype reference

**Imputed Data (VCF)** (`tests/input/`):
- `chr01.vcf.gz`, `chr02.vcf.gz`: Chromosome-specific VCF files
- ~500 samples, ~1000 variants per chromosome
- Used for REGENIE Step 2 and conversion tests

**Pre-converted PLINK1 Files** (`tests/input/`):
- `chr01.vcf.{bed,bim,fam}`, `chr02.vcf.{bed,bim,fam}`: PLINK1 format created from VCF
- Note: Filenames include ".vcf" prefix to indicate origin
- Used in conversion tests and workflows requiring chromosome-specific PLINK data

**Pre-converted PLINK2 Files** (`tests/input/`):
- `chr01.vcf.{pgen,psam,pvar}`, `chr02.vcf.{pgen,psam,pvar}`: PLINK2 format created from VCF
- Note: Filenames include ".vcf" prefix to indicate origin
- Used in GCTA mpfile tests and workflows requiring PLINK2 format

**Phenotype Files** (`tests/input/`):
- `phenotype.txt`: Multiple phenotypes (Y1, Y2)
- `phenotype_single.txt`: Single phenotype (Y1)
- `phenotype_bin.txt`: Binary trait
- `phenotype_no_header.txt`: Phenotypes without header
- `phenotypes_noheader.txt`: Alternative no-header format

**Covariate Files** (`tests/input/`):
- `covariates.txt`: Standard format with header (age, sex, PCs)
- `covariates_fixed.txt`: Fixed covariates
- `covariates_quant_noheader.txt`: Quantitative covariates without header
- `covariates_cat_noheader.txt`: Categorical covariates without header

**Batch Files** (`tests/input/`):
- `test_batch1`, `test_batch2`, `test_batch3`: Batch processing test files

**GCTA-Specific Test Data** (`tests/input/gcta/`):
> **Directory Reorganization (2025-12-15)**: All GCTA test directories are now **self-contained**. Each test directory contains both its input files (copied from upstream tests) and output files, eliminating cross-dependencies. The `calculate_ld_scores/` directory has been removed as it's no longer needed.

- Main files at `tests/input/gcta/`:
  - `gcta_grm.mpfile`, `gcta_grm.mgrm`, `batch_grm.mgrm`: Multi-part and multi-GRM files
  - `chr*.mpfile`: Per-chromosome multi-part files
  - `phenotype*.txt`, `covariates*.txt`: GCTA-specific formats

- Self-contained test directories (each with README.md):
  - `prepare_phenocov/`: PREPARE_PHENOCOV **outputs** only (phenotype/covariate formatting)
  - `make_mpfiles/`: MAKE_MPFILES **outputs** only (uses base test data)
  - `merge_mpfiles/`: MERGE_MPFILES **outputs** only (creates mock data inline)
  - `make_mgrm/`: **Input** (GRM files for validation) + **Output** (multi-GRM file)
  - `merge_snp_groups/`: **Input** (chr-specific SNP groups from CALCULATE_LD_SCORES) + **Output** (merged SNP groups)
  - `make_grm_part/`: **Input** (mpfile, SNP groups) + **Output** (GRM partitions)
  - `merge_grm_parts/`: **Input** (GRM partitions) + **Output** (merged GRMs)
  - `adjust_grm/`: **Input** (merged GRMs) + **Output** (adjusted GRMs)
  - `remove_related_subjects/`: **Input** (merged GRMs) + **Output** (unrelated GRMs)
  - `make_bk_sparse/`: **Input** (dense GRM) + **Output** (sparse GRM for FastGWA efficiency)
  - `run_fastgwa_mlm/`: **Input** (sparse GRM, phenotypes, covariates) + **Output** (FastGWA association results)

**LDAK-Specific Test Data** (`tests/input/ldak/`):
- LDAK kinship matrices and weighting files

**BOLT-LMM-Specific Test Data** (`tests/input/bolt_lmm/`):
- BOLT-LMM REML input files

**REGENIE-Specific Test Data** (`tests/input/regenie/`):
- REGENIE Step 1/Step 2 specific test inputs

### Test Outputs
- Snapshots stored in `*.nf.test.snap` files
- Temporary work directories (auto-cleaned by nf-test)
- Test reports (stdout/stderr)

---

## Key Dependencies and Configuration

### nf-test Configuration
Located in `nf-test.config`:
```groovy
config {
    testsDir = "tests"
    workDir = ".nf-test"
    configFile = "tests/nextflow.config"
}
```

### Test-specific Nextflow Config
`tests/nextflow.config` overrides main config for testing:
- May set minimal resources
- Can specify test-specific parameters
- Ensures reproducible test environment

### Dependencies
- **nf-test tool**: Installed separately from Nextflow
- **Test data**: Committed to repository (small datasets)
- **Containers**: Same Docker/Singularity images as production

---

## Data Models

### nf-test File Structure
```groovy
nextflow_process {
    name "TEST_PROCESS_NAME"
    script "path/to/process.nf"
    process "PROCESS_NAME"

    test("Test case description") {
        when {
            process {
                """
                input[0] = channel.of([...])
                input[1] = file("test_data.txt")
                """
            }
        }

        then {
            assert process.success
            assert snapshot(process.out).match()
        }
    }
}
```

### Snapshot Format
Snapshots capture:
- File content checksums (md5)
- File names and paths
- Channel structure and values

Example `.nf.test.snap`:
```json
{
  "Test case description": {
    "content": [
      {
        "0": [
          "output_file.txt:md5,abc123def456..."
        ]
      }
    ]
  }
}
```

---

## Testing and Quality

### Test Coverage

**Module Tests**:

*REGENIE (5 tests)*:
- `regenie_step1.nf.test`: Standard Step 1 execution
- `regenie_step1_split.nf.test`: Genotype chunking
- `regenie_step1_run_chunk.nf.test`: Chunk-specific execution
- `regenie_step1_merge_chunks.nf.test`: Prediction merging
- `regenie_step2.nf.test`: Association testing

*GCTA (18 tests)*:
- `prepare_phenocov.nf.test` ✅: Phenotype/covariate formatting (4 tests)
- `make_grm_part.nf.test` ✅: Partitioned GRM calculation (2 tests)
- `merge_grm_parts.nf.test` ✅: GRM partition merging (2 tests)
- `make_mpfiles.nf.test` ✅: Multi-part file creation (2 tests)
- `merge-mpfiles.nf.test` ✅: Multi-part file merging (1 test)
- `make_mgrm.nf.test` ✅: Multi-GRM file creation (1 test)
- `adjust_grm.nf.test` ✅: GRM covariate adjustment (2 tests)
- `remove_related_subjects.nf.test` ✅: Relatedness filtering (1 test)
- `run_reml.nf.test` ✅: REML variance estimation (2 tests)
- `run_fastgwa_mlm.nf.test` ✅: FastGWA mixed model (2 tests)
- `calculate_ld_scores.nf.test` ✅: LD score calculation (1 test)
- `make_bk_sparse.nf.test` ✅: Sparse GRM creation (2 tests)
- `merge_snp_groups.nf.test` ✅: SNP group merging (2 tests)

*LDAK (16 tests)*:
- `calc_kins_uniform.nf.test`: Uniform kinship
- `calc_kins_weights.nf.test`: Weighted kinship
- `calc_kins_human.nf.test`: Human-specific kinship
- `calc_kins_meta.nf.test`: Meta-analysis kinship
- `thin_predictors.nf.test`: LD-based thinning
- `create_thin_weights.nf.test`: Thinning weight creation
- `filter_relatedness.nf.test`: Relatedness filtering
- `add_grms.nf.test`: GRM addition
- `make_mgrm_ldak.nf.test`: Multi-GRM creation
- `ldak_reml.nf.test`: LDAK REML
- `ldak_he.nf.test`: Haseman-Elston regression
- `ldak_pcgc.nf.test`: PCGC liability-scale heritability
- `ldak_sumher.nf.test`: Summary-based heritability
- `ldak_sumcors.nf.test`: Summary-based correlations
- `calc_inflation.nf.test`: Genomic inflation
- `calc_genotype_error.nf.test`: Genotype error estimation

*BOLT-LMM (1 test)*:
- `run_reml.nf.test`: BOLT-LMM REML

*Data Conversion (2 tests)*:
- `imputed_to_plink.nf.test`: VCF to PLINK1
- `imputed_to_plink2.nf.test`: VCF to PLINK2

**Workflow Tests**:
- `main.nf.test`: Full pipeline integration
- `workflows/gcta/gcta_grm.nf.test` ✅: GRM calculation workflow (2 tests)
- `workflows/gcta/gcta_greml.nf.test` ✅: GREML heritability estimation (3 tests)
- `workflows/gcta/gcta_greml_ldms.nf.test` ✅: Partitioned heritability with LD stratification (2 tests)
- `workflows/gcta/gcta_fastgwa.nf.test` ✅: FastGWA association testing (3 tests)
- `workflows/ldak/ldak_qc.nf.test`: LDAK QC workflow
- `workflows/ldak/ldak_he.nf.test`: LDAK HE workflow
- `workflows/ldak/ldak_pcgc.nf.test`: LDAK PCGC workflow

### Continuous Integration
Tests run automatically on:
- Pull requests
- Commits to main branch
- Via GitHub Actions (`.github/workflows/ci-tests.yml`)

### Test Data Size
- Total test data: <50 MB
- Execution time: 5-10 minutes (all tests)
- Designed for CI/CD speed

---

## Test Data Management Procedures

### Standard Test Data Management Rule

**RULE: Always Copy Test Output Files After Successful Test Runs**

> **Prerequisite**: Run tests with `--profile test,singularity` to generate correct output files.

When you successfully run a test and it passes:

1. **Identify the output directory:**
   ```bash
   # Test outputs are in: .nf-test/tests/<test-hash>/work/<process-hash>/
   # Find the most recent test run
   find .nf-test/tests/ -type f -name "<expected_output_file>" | head -1
   ```

2. **Create a dedicated subdirectory:**
   ```bash
   # Name it after the process (lowercase, underscores)
   # For GCTA: tests/input/gcta/<process_name>/
   # For LDAK: tests/input/ldak/<process_name>/
   # For other tools: tests/input/<tool>/<process_name>/
   mkdir -p tests/input/<tool>/<process_name>/
   ```

3. **Copy ALL output files:**
   ```bash
   # Copy all relevant output files to the subdirectory
   cp .nf-test/tests/<hash>/work/<hash>/<output_files> tests/input/<tool>/<process_name>/
   ```

4. **Create or update subdirectory README:**
   ```bash
   # Create README.md in the process subdirectory
   # Document: Overview, Files, Process Details, Test Coverage, Workflow Context
   touch tests/input/<tool>/<process_name>/README.md
   ```

5. **Update tool-level README:**
   ```bash
   # Update tests/input/<tool>/README.md
   # - Add new section documenting the copied files
   # - Update "Test Results Summary" to mark test as passing
   # - Include file descriptions and their purpose
   ```

6. **Update tests/CLAUDE.md (THIS FILE):**
   ```bash
   # Update the "Test Data Inputs" section to reflect new subdirectory
   # Update the "Test Coverage" section to mark test as passing
   # Commit all documentation changes together
   ```

7. **Verify and commit:**
   ```bash
   ls -lh tests/input/<tool>/<process_name>/
   git add tests/input/<tool>/<process_name>/
   git add tests/input/<tool>/README.md
   git add tests/CLAUDE.md
   ```

**Example (MERGE_SNP_GROUPS):**
```bash
# 0. Run test with correct profile
nf-test test tests/modules/local/gcta/merge_snp_groups.nf.test --profile test,singularity

# 1. Find output
find .nf-test/tests/ -name "snp_group*.txt" | head -2

# 2. Create directory
mkdir -p tests/input/gcta/merge_snp_groups/

# 3. Copy files
cp .nf-test/tests/79f596.../work/14/f19f.../snp_group1.txt tests/input/gcta/merge_snp_groups/
cp .nf-test/tests/ec11b6.../work/f7/5ea5.../snp_group3.txt tests/input/gcta/merge_snp_groups/

# 4. Create subdirectory README
vim tests/input/gcta/merge_snp_groups/README.md

# 5. Update tool-level README
vim tests/input/gcta/README.md  # Added merge_snp_groups section, updated test count

# 6. Update tests/CLAUDE.md
vim tests/CLAUDE.md  # Updated GCTA-Specific Test Data section

# 7. Verify and commit
ls -lh tests/input/gcta/merge_snp_groups/
git add tests/input/gcta/merge_snp_groups/
git add tests/input/gcta/README.md
git add tests/CLAUDE.md
```

### Documentation Update Rule

**RULE: Always Update tests/CLAUDE.md When New Tests Work**

This file (`tests/CLAUDE.md`) is the central documentation for the testing framework. When you make any changes to the test infrastructure, you MUST update this file:

**Update Triggers:**
1. **New test passes**: Update "Test Coverage" section
2. **New test data added**: Update "Test Data Inputs" section with new subdirectories
3. **Test organization changes**: Update "Directory Structure" section
4. **New test tool added**: Add new subsection under "Test Data Inputs"

**Where to Update:**
- **Directory Structure** (lines 33-109): Update when new subdirectories are created
- **Test Data Inputs** (lines 153-202): Document new test data files and subdirectories
- **Test Coverage** (lines 288-343): Mark tests as passing/failing, update counts
- **Test Configuration Files** (lines 395-413): Update if test profiles change

**Commit Pattern:**
Always commit `tests/CLAUDE.md` together with:
- The new test data files
- Tool-specific README updates
- Process-specific README files

This ensures documentation stays synchronized with the actual test infrastructure.

---

## Frequently Asked Questions (FAQ)

**Q: How do I create a new test?**
A:
1. **Consult Context7** for nf-test best practices and syntax
2. Create `tests/modules/local/[tool]/myprocess.nf.test` (organize by tool)
3. Define test structure (see Data Models section)
4. Run test: `nf-test test tests/modules/local/[tool]/myprocess.nf.test --profile test,singularity`
5. Update snapshot: `nf-test test --update-snapshot --profile test,singularity`
6. Commit both `.nf.test` and `.nf.test.snap` files

**Q: What if snapshot doesn't match?**
A: Two scenarios:
1. **Unintentional change**: Bug introduced, fix code
2. **Intentional change**: Update expected output, run with `--update-snapshot --profile test,singularity`

**Q: Can I run tests without containers?**
A: Yes, if all tools (REGENIE, GCTA, etc.) are in PATH. Not recommended for reproducibility.

**Q: How do I debug failing tests?**
A:
1. Check test output (stdout/stderr)
2. Inspect `.nf-test/` work directory for intermediate files
3. Run individual process manually with test inputs
4. Add `--verbose` flag: `nf-test test <test-file> --verbose --profile test,singularity`

**Q: What's the difference between module and workflow tests?**
A:
- **Module tests**: Test single process in isolation
- **Workflow tests**: Test complete pipeline or workflow component
- Workflow tests are slower but provide integration validation

**Q: Can I use real data for testing?**
A: Yes, but not recommended for CI/CD. Real data should be in separate validation tests, not committed to repository.

---

## Test Configuration Files

### Test Profile Parameters (conf/test.config)
```groovy
params {
    project = 'test-gwas'
    genotypes_prediction = "$baseDir/tests/input/example.{bim,bed,fam}"
    genotypes_association = "$baseDir/tests/input/chr*.vcf.gz"
    phenotypes_filename = "$baseDir/tests/input/phenotype_single.txt"
    phenotypes_columns = 'Y1'
    covariates_filename = "$baseDir/tests/input/covariates.txt"
    nparts_gcta = 3
    batch_subset_prefix = "$baseDir/tests/input/test_batch"
    batch_subset_number = 3
}
```

### Resource Limits
All test processes use minimal resources (1 CPU, 1 GB RAM) for fast execution.

---

## Related File List

### Test Definitions
- `main.nf.test` - Full pipeline integration test
- `modules/local/regenie/*.nf.test` - REGENIE module tests (5 files)
- `modules/local/gcta/*.nf.test` - GCTA module tests (13 files)
- `modules/local/ldak/*.nf.test` - LDAK module tests (16 files)
- `modules/local/bolt_lmm/*.nf.test` - BOLT-LMM module tests (1 file)
- `modules/local/imputed_to_plink*.nf.test` - Conversion tests (2 files)
- `workflows/ldak/*.nf.test` - LDAK workflow tests (3 files)

### Test Data Categories
- `input/` - Main test data directory (all shared test files)
  - VCF files: `chr*.vcf.gz`
  - PLINK1 files: `example.{bed,bim,fam}`, `chr*.vcf.{bed,bim,fam}`
  - Phenotypes: `phenotype*.txt`
  - Covariates: `covariates*.txt`
  - Batch files: `test_batch*`
- `input/gcta/` - GCTA-specific test data
  - Mpfiles, MGRM files, phenotype/covariate formats
  - `calculate_ld_scores/` - LD scores and SNP group files (12 files)
  - `merge_snp_groups/` - Merged SNP groups (2 data + README)
  - Adjusted GRMs and unrelated subsets
- `input/ldak/` - LDAK-specific test data (kinship matrices, weights)
- `input/bolt_lmm/` - BOLT-LMM-specific test data (REML inputs)
- `input/regenie/` - REGENIE-specific test data (Step 1/2 inputs)

### Snapshot Files
- `*.nf.test.snap` - Expected output snapshots (auto-generated)
- Located alongside test files (e.g., `tests/modules/local/gcta/run_reml.nf.test.snap`)

---

## Related Documentation

- [Root Documentation](../CLAUDE.md)
- [Configuration](../conf/CLAUDE.md)
- [Modules](../modules/local/CLAUDE.md)
- [Workflows](../workflows/CLAUDE.md)
