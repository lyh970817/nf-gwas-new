# Test Batch Files for LDAK Genotype Error Estimation

## Overview

These batch subset files (`test_batch1`, `test_batch2`, `test_batch3`) are used for estimating genotype error rates in the LDAK QC workflow using Haseman-Elston (HE) regression.

## Files Created

- **test_batch1**: Samples 1-167 (167 samples)
- **test_batch2**: Samples 168-334 (167 samples)
- **test_batch3**: Samples 335-500 (166 samples)

Total: 500 samples divided into 3 batches

## File Format

Each batch file contains two columns (FID and IID) in PLINK format:
```
1 1
2 2
3 3
...
```

## Usage

To use these batch files in the nf-gwas pipeline, add the following parameters:

```bash
nextflow run main.nf \
  --batch_subset_prefix tests/input/pipeline/test_batch \
  --batch_subset_number 3 \
  -profile test,docker
```

## How It Works

1. **Parameter Setup**: When you specify `--batch_subset_prefix tests/input/pipeline/test_batch` and `--batch_subset_number 3`, the pipeline looks for files:
   - `tests/input/pipeline/test_batch1`
   - `tests/input/pipeline/test_batch2`
   - `tests/input/pipeline/test_batch3`

2. **LDAK Processing**: LDAK uses these files to:
   - Calculate genetic similarity within the same batch
   - Calculate genetic similarity between different batches
   - Estimate genotype error by comparing within-batch vs between-batch similarity

3. **Expected Output**: The genotype error results will be available at:
   - `${params.pubDir}/ldak/he/he_*.reml`

## Biological Context

Batch effects occur when samples are genotyped in different sequencing runs or on different arrays. By dividing samples into batches:
- **Within-batch pairs**: Should show higher genetic similarity (same technical conditions)
- **Between-batch pairs**: May show lower similarity due to batch-specific genotyping errors

The difference helps estimate technical error rates in your genotype data.

## Customization

To create your own batch files based on actual sequencing batches:

1. Identify which samples belong to each sequencing batch
2. Create separate files (one per batch) with FID and IID columns
3. Use a meaningful prefix (e.g., `seq_batch`, `array_batch`)
4. Update the parameters accordingly

Example:
```bash
--batch_subset_prefix data/seq_batch --batch_subset_number 5
```

This would look for files: `data/seq_batch1`, `data/seq_batch2`, ..., `data/seq_batch5`
