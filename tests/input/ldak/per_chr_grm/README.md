# Per-Chromosome GRM Test Data

Test data for per-chromosome kinship matrices used by `ADD_GRMS` process.

## Overview

This directory contains LDAK kinship matrices calculated per chromosome, which are inputs for combining into a genome-wide GRM.

## Files

### Chromosome 1 GRM
| File | Description | Size |
|------|-------------|------|
| `chr01.vcf.grm.bin` | Binary kinship matrix | 501K |
| `chr01.vcf.grm.id` | Sample IDs | 3.7K |
| `chr01.vcf.grm.details` | GRM calculation details | 60K |
| `chr01.vcf.grm.adjust` | Adjustment factors | 126B |

### Chromosome 2 GRM
| File | Description | Size |
|------|-------------|------|
| `chr02.vcf.grm.bin` | Binary kinship matrix | 501K |
| `chr02.vcf.grm.id` | Sample IDs | 3.7K |
| `chr02.vcf.grm.details` | GRM calculation details | 60K |
| `chr02.vcf.grm.adjust` | Adjustment factors | 126B |

### Multi-GRM File
| File | Description |
|------|-------------|
| `ldak_test.mgrm` | List of GRM prefixes for ADD_GRMS |

## Data Generation

Files generated from:
- `tests/input/ldak/chr01.vcf.gz` and `tests/input/ldak/chr02.vcf.gz`
- Using `CALC_KINS_UNIFORM` or similar LDAK kinship process
- 500 samples, ~500 variants per chromosome

## Usage in Tests

### ADD_GRMS Test
```groovy
input[0] = file("ldak_test.mgrm")
input[1] = [
    file("chr01.vcf.grm.bin"),
    file("chr01.vcf.grm.id"),
    file("chr01.vcf.grm.details"),
    file("chr01.vcf.grm.adjust"),
    file("chr02.vcf.grm.bin"),
    file("chr02.vcf.grm.id"),
    file("chr02.vcf.grm.details"),
    file("chr02.vcf.grm.adjust")
]
input[2] = "ldak_grm"
```

## Related Documentation

- [ADD_GRMS Module](../../../../modules/local/ldak/add_grms.nf)
- [LDAK Kinship Reference](../../../../modules/local/ldak/KINSHIP_REFERENCE.md)
