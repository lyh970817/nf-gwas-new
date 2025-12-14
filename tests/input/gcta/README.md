# GCTA Test Data

This directory contains test data files generated from successful nf-test runs for GCTA modules.

## Files

### Phenotype & Covariate Files
- `phenotype.txt` - Raw phenotype file with header (Y1, Y2)
- `phenotype.noheader.txt` - Phenotype file without header (processed by PREPARE_PHENOCOV)
- `covariates.txt` - Raw covariate file with header (V1, V2, Sex)
- `covariates.quant.noheader.txt` - Quantitative covariates without header (processed by PREPARE_PHENOCOV)
- `covariates.cat.noheader.txt` - Categorical covariates without header (processed by PREPARE_PHENOCOV)

### GRM & Kinship Files
- `gcta_grm_0.*` - Pre-computed Genetic Relationship Matrix files (from example.{bed,bim,fam})
  - Located in tests/input/pipeline/

### MPFILE (Multi-Part Files)

**Individual Chromosome Mpfiles (make_mpfiles/):**
- `chr01.vcf.mpfile` - PLINK2 mpfile for chromosome 1 (output from MAKE_MPFILES)
- `chr02.vcf.mpfile` - PLINK2 mpfile for chromosome 2 (output from MAKE_MPFILES)

**Merged Mpfiles (merge_mpfiles/):**
- `gcta_grm.mpfile` - Merged mpfile for genome-wide GRM computation (output from MERGE_MPFILES)

### MGRM (Multi-GRM Files)
- `gcta_grm.mgrm` - Multi-GRM file listing all GRM prefixes (one per line)

### REML Results
- `phenotypes_noheader.hsq` - REML heritability results (no covariates)
- `phenotypes_with_covariates.hsq` - REML heritability results (with covariates)

### LD Scores and SNP Groups (calculate_ld_scores/)
**LD Score Files:**
- `chr01.vcf_gcta_ld.score.ld` - LD scores for chromosome 1 (60K)
- `chr02.vcf_gcta_ld.score.ld` - LD scores for chromosome 2 (60K)

**SNP Group Files (segmented by LD score quartiles):**
- `chr01.vcf_snp_group1.txt` through `chr01.vcf_snp_group4.txt` - Chr1 SNP groups
- `chr02.vcf_snp_group1.txt` through `chr02.vcf_snp_group4.txt` - Chr2 SNP groups

**Log Files:**
- `chr01.vcf_gcta_ld.log` - GCTA LD calculation log for chr1
- `chr02.vcf_gcta_ld.log` - GCTA LD calculation log for chr2

### GRM Partitions (make_grm_part/)
**GRM Partition Files (output from MAKE_GRM_PART):**
- `gcta_grm_0.part_3_1.*` - GRM partition 1 of 3 (no SNP groups)
  - `gcta_grm_0.part_3_1.grm.id` - Sample IDs
  - `gcta_grm_0.part_3_1.grm.bin` - GRM matrix binary
  - `gcta_grm_0.part_3_1.grm.N.bin` - Sample counts
  - `gcta_grm_0.part_3_1.log` - GCTA process log
- `gcta_grm_0.part_3_2.*` - GRM partition 2 of 3 (for merge testing)
- `gcta_grm_0.part_3_3.*` - GRM partition 3 of 3 (for merge testing)
- `gcta_grm_1.part_5_2.*` - GRM partition 2 of 5 (SNP group 1 filtering)
  - `gcta_grm_1.part_5_2.grm.id` - Sample IDs
  - `gcta_grm_1.part_5_2.grm.bin` - GRM matrix binary
  - `gcta_grm_1.part_5_2.grm.N.bin` - Sample counts
  - `gcta_grm_1.part_5_2.log` - GCTA process log
- `gcta_grm_1.part_2_1.*` - GRM partition 1 of 2 (SNP group 1, for merge testing)
- `gcta_grm_1.part_2_2.*` - GRM partition 2 of 2 (SNP group 1, for merge testing)

### Merged GRM Partitions (merge_grm_parts/)
**Merged GRM Files (output from MERGE_GRM_PARTS):**
- `gcta_grm_0.grm.*` - Merged GRM (all SNPs, 3 partitions merged)
  - `gcta_grm_0.grm.id` - Sample IDs (5.3 KB)
  - `gcta_grm_0.grm.bin` - Merged GRM matrix binary (371 KB)
  - `gcta_grm_0.grm.N.bin` - Sample counts binary (371 KB)
- `gcta_grm_1.grm.*` - Merged GRM (SNP group 1, 2 partitions merged)
  - `gcta_grm_1.grm.id` - Sample IDs (1.7 KB)
  - `gcta_grm_1.grm.bin` - Merged GRM matrix binary (200 KB)
  - `gcta_grm_1.grm.N.bin` - Sample counts binary (200 KB)

### Merged SNP Groups (merge_snp_groups/)
**Merged SNP Group Files (output from MERGE_SNP_GROUPS):**
- `snp_group1.txt` - Merged high LD SNPs from chr01 + chr02
- `snp_group3.txt` - Merged low LD SNPs from chr01 + chr02

## Test Results Summary

### Passing (16/24 tests)
- ✅ PREPARE_PHENOCOV (3 tests)
- ✅ MAKE_MPFILES (2 tests)
- ✅ MERGE_MPFILES (1 test)
- ✅ MAKE_MGRM (1 test)
- ✅ RUN_REML (2 tests)
- ✅ CALCULATE_LD_SCORES (1 test)
- ✅ MERGE_SNP_GROUPS (2 tests)
- ✅ MAKE_GRM_PART (2 tests)
- ✅ MERGE_GRM_PARTS (2 tests)

### Failing (8/24 tests)
Tests requiring additional pre-computed files:
- ADJUST_GRM (2) - Needs gcta_grm_0_adj.* files
- REMOVE_RELATED_SUBJECTS (1) - Needs gcta_grm_0_unrel05.* files
- MAKE_BK_SPARSE (2) - Needs source GRM
- RUN_FASTGWA_MLM (2) - Needs sparse GRM
- GCTA_GREML (1) - Needs full workflow setup

## Test Data Management

**For complete test data management procedures**, see the **"Test Data Management Procedures"** section in [tests/CLAUDE.md](../../CLAUDE.md#test-data-management-procedures).

The standard workflow is:
1. Run test and confirm it passes
2. Copy output files to `tests/input/gcta/<process_name>/`
3. Create subdirectory README.md
4. Update this README.md
5. Update `tests/CLAUDE.md`
6. Commit all changes together
