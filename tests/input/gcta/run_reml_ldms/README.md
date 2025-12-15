# RUN_REML_LDMS Test Data

This directory contains test data for the **RUN_REML_LDMS** process, which runs multi-component REML analysis using multiple GRMs for GCTA GREML-LDMS (LD-stratified partitioned heritability).

## Overview

**Process**: `RUN_REML_LDMS`
**Module**: `modules/local/gcta/run_reml_ldms.nf`
**Test**: `tests/modules/local/gcta/run_reml_ldms.nf.test`
**Status**: ✅ **PASSING** (2 tests)

## Files

### Input Files (GRM Data)
These GRM files are required by GCTA for multi-component REML analysis:

- `gcta_grm_1.grm.bin` - Binary GRM matrix for first SNP group (e.g., high LD)
- `gcta_grm_1.grm.id` - Sample IDs for first GRM
- `gcta_grm_1.grm.N.bin` - Sample count per SNP for first GRM
- `gcta_grm_2.grm.bin` - Binary GRM matrix for second SNP group (e.g., low LD)
- `gcta_grm_2.grm.id` - Sample IDs for second GRM
- `gcta_grm_2.grm.N.bin` - Sample count per SNP for second GRM
- `gcta_grm.mgrm` - Multi-GRM file listing GRM prefixes (input to process)

### Phenotype & Covariate Files
- `phenotype.noheader.txt` - Phenotypes (Y1, Y2) for 500 samples, no header (22 KB)
- `covariates.quant.noheader.txt` - Quantitative covariates (V1, V2), no header (22 KB)
- `covariates.cat.noheader.txt` - Categorical covariate (binary), no header (4.7 KB)

### Output Files
- `phenotype.noheader.hsq` - Multi-component REML results without covariates
- `phenotype.noheader_with_covariates.hsq` - Multi-component REML results with both covariate types (263 bytes)

## Process Details

### RUN_REML_LDMS
**Purpose**: Execute multi-component REML analysis to partition heritability across multiple GRMs (e.g., by LD score groups)

**Input**:
- `path mgrm_file`: Multi-GRM file listing all GRM prefixes
- `path grm_files`: All GRM files (.id, .bin, .N.bin for each prefix)
- `path phenotypes_file`: Phenotype file (no header)
- `path qcovariates_file`: Quantitative covariates (optional)
- `path covariates_file`: Categorical covariates (optional)

**Output**:
- `path "*.hsq"`: REML results with variance components for each GRM

**Script Logic**:
```bash
gcta \
    --reml \
    --mgrm ${mgrm_file} \
    --pheno ${phenotypes_file} \
    [--qcovar ${qcovariates_file}] \
    [--covar ${covariates_file}] \
    --out ${out} \
    --thread-num ${task.cpus}
```

### Key Differences from RUN_REML
- Uses `--mgrm` flag instead of `--grm` to specify multiple GRMs
- Estimates separate variance components for each GRM
- Enables partitioned heritability analysis (e.g., by LD quartiles)

### Expected Output Content
The `.hsq` file contains:
```
Source  Variance        SE
V(G1)   0.15           0.05    # Variance explained by first GRM
V(G2)   0.25           0.06    # Variance explained by second GRM
V(e)    0.60           0.04    # Residual variance
Vp      1.00           NA      # Total phenotypic variance
```

Plus log-likelihood, heritability estimates per component, etc.

## Test Coverage

### Test Case 1: "Should execute multi-component REML with MGRM file"
**Status**: ✅ PASSING

- **Input**:
  - MGRM file with 2 GRM prefixes (`gcta_grm_1`, `gcta_grm_2`)
  - All GRM files staged (.id, .bin, .N.bin for both)
  - Phenotype file (no header)
  - No covariates
- **Expected Output**:
  - `phenotype.noheader.hsq` - Multi-component REML results
  - Contains `V(G1)`, `V(G2)`, `V(e)`, `Vp`
  - File size > 0
- **Assertions**:
  - Process completes successfully
  - Output file exists and is non-empty
  - File contains variance component labels (V(G), Vp, Variance, or V(e))

---

### Test Case 2: "Should execute multi-component REML with covariates"
**Status**: ✅ PASSING

- **Input**:
  - MGRM file with 2 GRM prefixes (`gcta_grm_1`, `gcta_grm_2`)
  - All GRM files staged (.id, .bin, .N.bin for both)
  - Phenotype file (no header)
  - Quantitative covariates: `covariates.quant.noheader.txt` (V1, V2)
  - Categorical covariates: `covariates.cat.noheader.txt` (binary covariate)
- **Expected Output**:
  - `phenotype.noheader_with_covariates.hsq` - Multi-component REML results adjusted for covariates
- **Assertions**:
  - Process completes successfully
  - Output matches snapshot

## Workflow Context

### Upstream Dependencies
- **CALCULATE_LD_SCORES**: Segments SNPs into groups by LD score
- **MERGE_SNP_GROUPS**: Merges SNP groups across chromosomes
- **GCTA_GRM**: Calculates separate GRM for each SNP group
- **MAKE_MGRM**: Creates MGRM file listing all GRM prefixes

### Downstream Usage
- **GCTA_GREML_LDMS workflow**: Uses RUN_REML_LDMS for LD-stratified heritability estimation
- Results show whether high-LD regions contribute more per-SNP heritability

### Use Cases
1. **GREML-LDMS**: Partition heritability by LD quartiles (typically 4 GRMs)
2. **Functional partitioning**: Separate GRMs for coding vs. non-coding variants
3. **MAF stratification**: Test heritability enrichment in different frequency bins
4. **Gene set analysis**: Partition by gene sets or pathways

## Notes

- The MGRM file lists GRM prefixes; GCTA expects to find `.grm.bin`, `.grm.id`, and `.grm.N.bin` for each
- All GRMs must be calculated from the same sample set (same individuals)
- Multi-component REML is more computationally intensive than single-component
- Variance components are constrained to be non-negative
- Test uses 2 GRMs for simplicity; real GREML-LDMS typically uses 4 (LD quartiles)

## Related Documentation

- [GCTA Modules](../../../../modules/local/gcta/CLAUDE.md)
- [GCTA Workflows](../../../../workflows/gcta/CLAUDE.md)
- [GCTA Test Data Overview](../README.md)
- [Root Documentation](../../../../../CLAUDE.md)
- [GCTA GREML-LDMS Documentation](https://yanglab.westlake.edu.cn/software/gcta/#GREMLinWGSorimputeddata)
