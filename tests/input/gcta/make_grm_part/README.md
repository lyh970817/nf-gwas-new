# GCTA MAKE_GRM_PART Test Data

## Overview
Test output files for the `MAKE_GRM_PART` process, which calculates partitioned Genomic Relationship Matrices (GRM) from PLINK2 genotype data.

## Files

### Test 1: No SNP Groups (3 partitions)
- **gcta_grm_0.part_3_1.grm.id** (1.8 KB)
  - Sample identifiers (individual IDs) included in partition 1
  - Format: FID IID (family ID, individual ID)

- **gcta_grm_0.part_3_1.grm.bin** (124 KB)
  - Binary GRM values for partition 1 of 3
  - Contains pairwise kinship coefficients

- **gcta_grm_0.part_3_1.grm.N.bin** (124 KB)
  - Count of SNPs used in kinship calculation for each pair
  - Diagnostic for SNP coverage across individuals

### Test 2: SNP Group Filtering (5 partitions, group 1)
- **gcta_grm_1.part_5_2.grm.id** (848 B)
  - Sample identifiers for partition 2 with SNP group 1 filtering
  - Smaller than partition 1 due to SNP group filtering

- **gcta_grm_1.part_5_2.grm.bin** (100 KB)
  - Binary GRM values for partition 2 of 5 with SNP group 1 filtering
  - Calculated only from SNPs in the specified group

- **gcta_grm_1.part_5_2.grm.N.bin** (100 KB)
  - SNP count for each pair in SNP group 1

## Process Details

### MAKE_GRM_PART
- **Input**: PLINK2 genotype files (pgen/psam/pvar) and mpfile specification
- **Output**: Partitioned GRM files for subsequent merging
- **Purpose**:
  - Divide chromosome-wide GRM calculation into partitions for parallelization
  - Optionally filter to SNP groups for LD-weighted analysis
  - Enables memory-efficient processing of large datasets

## Test Coverage

### Test 1: "Should calculate GRM partition without SNP groups"
- Tests basic GRM partition calculation
- Verifies output structure: nparts (3), snp_group (null), and 3 GRM files
- Validates file naming: `gcta_grm_0.part_3_1.grm.*`
- Confirms file existence and non-zero size

### Test 2: "Should calculate GRM partition with SNP group filtering"
- Tests SNP group-filtered GRM partition
- Verifies output with SNP group filtering: nparts (5), snp_group (1)
- Validates file naming: `gcta_grm_1.part_5_2.grm.*`
- Uses snapshot testing for output validation

## Workflow Context

### Typical GRM Calculation Pipeline
```
GCTA Genotypes → MAKE_MPFILES (per-chromosome) →
MERGE_MPFILES (genome-wide) →
MAKE_GRM_PART (per-partition) →
MERGE_GRM_PARTS (final GRM) →
ADJUST_GRM (covariate adjustment) →
Final GRM files
```

### SNP Group-Filtered Pipeline (LDAK-style LD weighting)
```
CALCULATE_LD_SCORES → MERGE_SNP_GROUPS →
MAKE_GRM_PART (with SNP group) →
MERGE_GRM_PARTS → Final LD-weighted GRM
```

## Data Source
- Genotypes: `tests/input/chr*.vcf.{pgen,psam,pvar}` (test data)
- Mpfile: `tests/input/gcta/merge_mpfiles/gcta_grm.mpfile`
- SNP group: `tests/input/gcta/merge_snp_groups/snp_group1.txt`
- Test command: `nf-test test tests/modules/local/gcta/make_grm_part.nf.test --profile test,singularity`

## Test Status
✅ Both tests passing (2/2)
