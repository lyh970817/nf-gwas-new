# MAKE_MPFILES Test Data

## Overview

This directory contains expected output files from the `MAKE_MPFILES` process, which creates multi-part files (mpfiles) for GCTA GRM calculation. Each mpfile lists the PLINK2 file paths for a single chromosome.

## Files

### chr01.vcf.mpfile
- **Description**: Multi-part file specification for chromosome 1
- **Format**: Space-delimited text: `filename pgen_path psam_path pvar_path`
- **Content**: `chr01.vcf chr01.vcf.pgen chr01.vcf.psam chr01.vcf.pvar`
- **Size**: 55 bytes
- **Source**: Output from MAKE_MPFILES process test

### chr02.vcf.mpfile
- **Description**: Multi-part file specification for chromosome 2
- **Format**: Space-delimited text: `filename pgen_path psam_path pvar_path`
- **Content**: `chr02.vcf chr02.vcf.pgen chr02.vcf.psam chr02.vcf.pvar`
- **Size**: 55 bytes
- **Source**: Output from MAKE_MPFILES process test

## Process Details

**Process**: `MAKE_MPFILES`
**Module**: `modules/local/gcta/make_mpfiles.nf`
**Purpose**: Create individual mpfile for each chromosome to enable parallelized GRM calculation

**Input**:
- Tuple: `(chr_num, filename, pgen, psam, pvar, range)`
- PLINK2 format files for a single chromosome

**Output**:
- `${filename}.mpfile`: Text file with one line containing file paths

**Script**:
```bash
echo "${filename} ${plink2_pgen_file} ${plink2_psam_file} ${plink2_pvar_file}" > ${filename}.mpfile
```

## Test Coverage

**Test File**: `tests/modules/local/gcta/make_mpfiles.nf.test`

**Test Cases**:
1. ✅ "Should create mpfile from PLINK2 files" - Tests chr01.vcf
2. ✅ "Should handle different chromosomes" - Tests chr02.vcf

**Assertions**:
- File is created with correct name (`${filename}.mpfile`)
- File contains all 4 space-delimited fields
- First field matches the filename
- File contains .pgen, .psam, .pvar extensions

## Workflow Context

These mpfiles are used in the GCTA GRM calculation workflow:
1. **MAKE_MPFILES**: Create individual mpfiles per chromosome (this process)
2. **MERGE_MPFILES**: Concatenate all chromosome mpfiles into single file
3. **MAKE_GRM_PART**: Use merged mpfile to calculate GRM partitions
4. **MERGE_GRM_PARTS**: Combine partitions into final GRM

## Related Documentation

- [GCTA Modules](../../modules/local/gcta/CLAUDE.md)
- [GCTA Workflows](../../workflows/gcta/CLAUDE.md)
- [Test Documentation](../../CLAUDE.md)
