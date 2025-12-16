# LDAK-KVIK Steps

LDAK-KVIK performs association testing through three sequential steps:

1. **Step 1**: Compute Leave-One-Chromosome-Out (LOCO) PRS using Elastic Net
2. **Step 2**: Conduct single-SNP analysis using PRS as offset
3. **Step 3**: Execute gene-based association analysis via LDAK-GBAT

Each step depends on outputs from the previous step and must be run consecutively.

## Step 1: LOCO PRS Computation

### Command Syntax

```bash
./ldak6.1.linux --kvik-step1 kvik --bfile data --pheno phenofile \
  --covar covfile --max-threads 2
```

### Main Parameters

| Argument | Description |
|----------|-------------|
| `--kvik-step1` | Output file name for Step 1 results |
| `--bfile` | Binary genotype file (.bed) path |
| `--pheno` | Phenotype file path |
| `--covar` | Covariate file path |
| `--max-threads` | Thread count for Elastic Net fitting (default: 1) |
| `--binary` | Use `--binary YES` for binary traits |

### Important Recommendations

Users may employ a subset of SNPs to compute LOCO PRS and estimate lambda, which substantially reduces run time with minimal impact on statistical performance. See [Recommendations](recommendations.md) for SNP reduction strategies.

For binary traits, weighted linear regression replaces standard linear regression.

## Step 2: Single-SNP Analysis

### Command Syntax

```bash
./ldak6.1.linux --kvik-step2 kvik --bfile data --pheno phenofile \
  --covar covfile --max-threads 2
```

### Main Parameters

| Argument | Description |
|----------|-------------|
| `--kvik-step2` | Output file name (must match `--kvik-step1` name) |
| `--bfile` | Binary genotype file path |
| `--pheno` | Phenotype file path |
| `--covar` | Covariate file path |

### Requirements

- The `--kvik-step2` identifier must match the Step 1 identifier
- Binary trait designation automatically carries forward from Step 1
- Saddlepoint approximation applies to binary phenotypes
- Step 2 cannot execute before Step 1 completion

## Step 3: Gene-Based Analysis

### Command Syntax

```bash
./ldak6.1.linux --kvik-step3 kvik --bfile data --genefile annotfile \
  --max-threads 2
```

### Main Parameters

| Argument | Description |
|----------|-------------|
| `--kvik-step3` | Output file name (must match Steps 1 and 2) |
| `--bfile` | Binary genotype file path |
| `--genefile` | Gene annotation file specifying genomic locations |

### Requirements

A gene annotation file is mandatory for specifying gene positions across the genome. Download from:
- GRCh37: https://dougspeed.com/wp-content/uploads/RefSeq_GRCh37.txt
- GRCh38: https://dougspeed.com/wp-content/uploads/RefSeq_GRCh38.txt
