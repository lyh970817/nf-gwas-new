# MAKE_BK_SPARSE Test Data

## Overview

Test data for the `MAKE_BK_SPARSE` process, which creates sparse genetic relationship matrices (GRMs) from dense GRMs by filtering out values below a specified cutoff threshold.

**Process**: `modules/local/gcta/make_bk_sparse.nf`
**Test File**: `tests/modules/local/gcta/make_bk_sparse.nf.test`

---

## Files

### Input Files (Dense GRM)

| File | Size | Description |
|------|------|-------------|
| `gcta_grm_0.grm.id` | 3.7 KB | Individual IDs (500 samples) |
| `gcta_grm_0.grm.bin` | 490 KB | Dense GRM values (binary) |
| `gcta_grm_0.grm.N.bin` | 490 KB | Number of SNPs used per pair (binary) |

### Output Files (Sparse GRM)

| File | Size | Description |
|------|------|-------------|
| `gcta_grm_0_sp.grm.id` | 3.7 KB | Individual IDs in sparse format |
| `gcta_grm_0_sp.grm.sp` | 132 KB | Sparse GRM values (only values > cutoff) |

**Sparsity**: ~73% reduction in file size (132 KB vs 490 KB), indicating most GRM values < 0.05

---

## Process Details

**Purpose**: Convert dense GRM to sparse format for FastGWA efficiency

**GCTA Command**:
```bash
gcta \
    --grm gcta_grm_0 \
    --make-bK-sparse <cutoff> \
    --out gcta_grm_0_sp
```

**Key Parameters**:
- `--make-bK-sparse 0.05`: Keep only GRM values > 0.05 (default cutoff)
- Sparse format stores only non-zero elements for memory efficiency

**Expected Behavior**:
- Retains only related pairs and self-relatedness (diagonal)
- Typical sparsity: 95-99% for large population cohorts
- Enables scalable FastGWA analysis for biobank-scale data

---

## Test Coverage

**Test 1: "Should create sparse GRM from dense GRM"**
- Cutoff: 0.05 (standard)
- Validates: File creation, naming convention, non-empty outputs

**Test 2: "Should create sparse GRM with different cutoff"**
- Cutoff: 0.025 (stricter threshold)
- Validates: Snapshot consistency, parameter sensitivity
- Expected: Larger output file (more values retained)

---

## Workflow Context

This process is part of the **GCTA FastGWA** workflow:

```
Dense GRM → MAKE_BK_SPARSE → Sparse GRM → RUN_FASTGWA_MLM → Association results
```

**Upstream**: `MERGE_GRM_PARTS` (dense GRM creation)
**Downstream**: `RUN_FASTGWA_MLM` (association testing)

---

## Data Provenance

**Source**: Output from GCTA `--make-grm` on example.{bed,bim,fam} dataset
**Samples**: 500 individuals
**SNPs**: ~1,000 variants
**Created**: 2025-12-15
**Test Status**: ✅ PASSING (2 tests)
