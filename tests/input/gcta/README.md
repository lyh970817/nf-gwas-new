# GCTA Test Data

This directory contains test data files for GCTA module tests. Each subdirectory is **self-contained** with both input and output files for its corresponding test.

## Directory Structure

Each test directory contains:
1. **Input files** - Test data required by the process
2. **Output files** - Expected outputs from successful test runs
3. **README.md** - Detailed documentation for that test

This self-contained structure ensures each test can reference its own directory for all required files.

## Files

### Phenotype & Covariate Files
- `phenotype.txt` - Raw phenotype file with header (Y1, Y2)
- `phenotype.noheader.txt` - Phenotype file without header (processed by PREPARE_PHENOCOV)
- `covariates.txt` - Raw covariate file with header (V1, V2, Sex)
- `covariates.quant.noheader.txt` - Quantitative covariates without header (processed by PREPARE_PHENOCOV)
- `covariates.cat.noheader.txt` - Categorical covariates without header (processed by PREPARE_PHENOCOV)

### Prepared Phenotype/Covariate Files (prepare_phenocov/)
- Contains **output files only** from PREPARE_PHENOCOV test
- **Input**: Base phenotype/covariate files from `tests/input/`
- **Output**: Header-removed and separated covariate files
  - `phenotype.noheader.txt` - Phenotypes without header (500 samples, 2 phenotypes, 22K)
  - `covariates.quant.noheader.txt` - Quantitative covariates (V2, V3, 22K)
  - `covariates.cat.noheader.txt` - Categorical covariate (V1, 4.7K)
- **Purpose**: Demonstrates GCTA-compatible file formatting
- **Test**: `tests/modules/local/gcta/prepare_phenocov.nf.test` (4 test cases)

### GRM & Kinship Files
- `gcta_grm_0.*` - Pre-computed Genetic Relationship Matrix files (from example.{bed,bim,fam})
  - Located in tests/input/pipeline/

### MPFILE (Multi-Part Files)

**Individual Chromosome Mpfiles (make_mpfiles/):**
- Contains output files from MAKE_MPFILES test
- Test uses base PLINK2 genotype data from `tests/input/chr*.vcf.{pgen,psam,pvar}`
- Self-contained test (no external dependencies from other GCTA tests)

**Merged Mpfiles (merge_mpfiles/):**
- Contains output files from MERGE_MPFILES test
- Test creates mock mpfiles inline (self-contained)
- No external dependencies

### MGRM (Multi-GRM Files) (make_mgrm/)
- Contains **both input and output files** for MAKE_MGRM test
- **Input**: GRM files for validation (not directly read by process)
  - `gcta_grm_1.grm.{bin,id,N.bin}` - First GRM
  - `gcta_grm_2.grm.{bin,id,N.bin}` - Second GRM
- **Output**: Multi-GRM file listing GRM prefixes
  - `gcta_grm.mgrm` - Text file with one GRM prefix per line
- **Purpose**: Self-contained test directory

### REML Results
- `phenotypes_noheader.hsq` - REML heritability results (no covariates)
- `phenotypes_with_covariates.hsq` - REML heritability results (with covariates)

### Merged SNP Groups (merge_snp_groups/)
- Contains **both input and output files** for MERGE_SNP_GROUPS test
- **Input**: Per-chromosome SNP group files (originally from CALCULATE_LD_SCORES test)
  - `chr01.vcf_snp_group1.txt`, `chr02.vcf_snp_group1.txt`
  - `chr01.vcf_snp_group3.txt`, `chr02.vcf_snp_group3.txt`
- **Output**: Merged genome-wide SNP group files
  - `snp_group1.txt`, `snp_group3.txt`
- **Purpose**: Self-contained test directory
- **Note**: CALCULATE_LD_SCORES test creates its outputs in nf-test work directory

### GRM Partitions (make_grm_part/)
- Contains **both input and output files** for MAKE_GRM_PART test
- **Input**:
  - `gcta_grm.mpfile` (copied from `merge_mpfiles/`)
  - `snp_group1.txt` (copied from `merge_snp_groups/`)
  - Base genotype data from `tests/input/chr*.vcf.{pgen,psam,pvar}`
- **Output**: GRM partition files
- **Purpose**: Self-contained test directory

### Merged GRM Partitions (merge_grm_parts/)
- Contains **both input and output files** for MERGE_GRM_PARTS test
- **Input**: GRM partition files (copied from `make_grm_part/`)
- **Output**: Merged genome-wide GRM files
- **Purpose**: Self-contained test directory

### Adjusted GRMs (adjust_grm/)
- Contains **both input and output files** for ADJUST_GRM test
- **Input**: Merged GRM files (copied from `merge_grm_parts/`)
- **Output**: Adjusted GRM files with `_adj` suffix
- **Purpose**: Self-contained test directory

### Unrelated Subjects (remove_related_subjects/)
- Contains **both input and output files** for REMOVE_RELATED_SUBJECTS test
- **Input**: Merged GRM files (copied from `merge_grm_parts/`)
- **Output**: Filtered GRM files with `_unrel05` suffix
- **Purpose**: Self-contained test directory

### Sparse GRM (make_bk_sparse/)
- Contains **both input and output files** for MAKE_BK_SPARSE test
- **Input**: Dense GRM files (gcta_grm_0.grm.{id,bin,N.bin})
  - `gcta_grm_0.grm.id` - Individual IDs (3.7 KB, 500 samples)
  - `gcta_grm_0.grm.bin` - Dense GRM values (490 KB)
  - `gcta_grm_0.grm.N.bin` - Number of SNPs per pair (490 KB)
- **Output**: Sparse GRM files (only values > cutoff)
  - `gcta_grm_0_sp.grm.id` - Individual IDs (3.7 KB)
  - `gcta_grm_0_sp.grm.sp` - Sparse GRM values (132 KB, ~73% reduction)
- **Purpose**: Creates sparse GRM for FastGWA efficiency (cutoff: 0.05)
- **Test**: Tests two different cutoffs (0.05 standard, 0.025 stricter)

### FastGWA-MLM Association Tests (run_fastgwa_mlm/)
- Contains **both input and output files** for RUN_FASTGWA_MLM test
- **Input**:
  - `phenotype.noheader.txt` - Phenotypes (Y1, Y2) for 500 samples, no header (22 KB)
  - `covariates.quant.noheader.txt` - Quantitative covariates (V1, V2), no header (22 KB)
  - `covariates.cat.noheader.txt` - Categorical covariates, no header (4.7 KB)
  - `gcta_grm_0_sp.grm.id` - Sparse GRM sample IDs (3.7 KB, 500 samples)
  - `gcta_grm_0_sp.grm.sp` - Sparse GRM values (132 KB, row col value format)
  - Base genotype data from `tests/input/chr01.vcf.{pgen,psam,pvar}`
- **Output**: FastGWA association results
  - `chr01.vcf_phenotype.noheader.fastGWA` - Association results without covariates (57 KB)
  - `chr01.vcf_phenotype.noheader_with_covariates.fastGWA` - Association results with covariates (57 KB)
- **Purpose**: Execute FastGWA-mlm mixed linear model association tests with sparse GRM
- **Test**: 2 test cases (basic test, test with quantitative covariates)

## Test Results Summary

### Passing (21/25 tests)
- ✅ PREPARE_PHENOCOV (4 tests)
- ✅ MAKE_MPFILES (2 tests)
- ✅ MERGE_MPFILES (1 test)
- ✅ MAKE_MGRM (1 test)
- ✅ RUN_REML (2 tests)
- ✅ CALCULATE_LD_SCORES (1 test)
- ✅ MERGE_SNP_GROUPS (2 tests)
- ✅ MAKE_GRM_PART (2 tests)
- ✅ MERGE_GRM_PARTS (2 tests)
- ✅ MAKE_BK_SPARSE (2 tests)
- ✅ RUN_FASTGWA_MLM (2 tests)

### Failing (4/25 tests)
Tests requiring additional pre-computed files:
- ADJUST_GRM (2) - Needs gcta_grm_0_adj.* files
- REMOVE_RELATED_SUBJECTS (1) - Needs gcta_grm_0_unrel05.* files
- GCTA_GREML (1) - Needs full workflow setup

## Test Data Reorganization

**Important**: As of 2025-12-15, all test directories have been reorganized to be **self-contained**:
- Each test directory now contains its required **input files** (copied from upstream test outputs)
- Each test references files in its **own directory** only
- This eliminates cross-dependencies between test directories
- Makes tests easier to understand and maintain
- Removed `calculate_ld_scores/` directory - the CALCULATE_LD_SCORES test creates its outputs in nf-test work directory; downstream tests have their own copies of needed files
