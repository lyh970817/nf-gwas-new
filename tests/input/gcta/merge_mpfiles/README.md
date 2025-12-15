# MERGE_MPFILES Test Data

## Overview

This directory contains expected output from the `MERGE_MPFILES` process, which concatenates individual chromosome mpfiles into a single merged file for genome-wide GRM calculation.

## Files

### gcta_grm.mpfile
- **Description**: Merged multi-part file containing specifications for all chromosomes
- **Format**: Multi-line text file, one chromosome per line
- **Content**:
  ```
  chr1 path/to/chr1.pgen path/to/chr1.psam path/to/chr1.pvar
  chr2 path/to/chr2.pgen path/to/chr2.psam path/to/chr2.pvar
  ```
- **Size**: 118 bytes (2 lines)
- **Source**: Output from MERGE_MPFILES process test

## Process Details

**Process**: `MERGE_MPFILES`
**Module**: `modules/local/gcta/merge_mpfiles.nf`
**Purpose**: Combine all chromosome mpfiles into single file for genome-wide GRM calculation

**Input**:
- `path mpfile_parts`: Collection of all chromosome .mpfile files

**Output**:
- `gcta_grm.mpfile`: Single merged file containing all chromosome specifications

**Script**:
```bash
cat ${mpfile_parts.join(' ')} > gcta_grm.mpfile
```

## Test Coverage

**Test File**: `tests/modules/local/gcta/merge-mpfiles.nf.test`

**Test Cases**:
1. ✅ "Should merge multiple mpfiles into a single file"

**Assertions**:
- Output file is named `gcta_grm.mpfile`
- File contains expected number of lines (one per input chromosome)
- Each line starts with correct chromosome identifier
- Lines maintain correct format from individual mpfiles

## Workflow Context

The merged mpfile is used in GCTA GRM calculation:
1. **MAKE_MPFILES**: Create individual mpfiles per chromosome
2. **MERGE_MPFILES**: Concatenate into single file (this process)
3. **MAKE_GRM_PART**: Read merged mpfile to calculate GRM partitions in parallel
4. **MERGE_GRM_PARTS**: Combine partitions into final GRM

**Why merge mpfiles?**
- GCTA's `--mpfile` option reads a single file listing all chromosome data
- Enables parallelized GRM calculation across partitions while accessing all chromosomes
- Each GRM partition reads the same merged mpfile but computes different subset of the matrix

## Related Documentation

- [GCTA Modules](../../modules/local/gcta/CLAUDE.md)
- [GCTA Workflows](../../workflows/gcta/CLAUDE.md)
- [Test Documentation](../../CLAUDE.md)
