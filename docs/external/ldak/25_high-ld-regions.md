# High-LD Regions

## Overview

DougSpeed.com provides reference files identifying high-LD (linkage disequilibrium) regions for genomic analysis. Two versions are available based on different human genome assemblies.

## Download Resources

- **highld_hg19.txt** – High-LD regions based on GRCh37/hg19 assembly
- **highld_hg38.txt** – High-LD regions based on GRCh38/GRCh37 assembly

## Recommended Usage

The documentation suggests "excluding SNPs in high-LD regions when using Principal Component Analysis to detect outliers or construct population covariates."

To identify SNPs within these regions, users can employ the `--cut-genes` command (detailed in Gene-based Analysis documentation).

## Example Implementation

The walkthrough uses test PLINK binary files (human.bed, human.bim, human.fam) with the highld_hg19.txt file. Since the test dataset only includes Chromosomes 21 & 22 (which lack actual high-LD regions), a demonstration region is artificially added:

```bash
echo "Region25 21  14600000 14700000" | cat highld_hg19.txt - > highld.fake
```

To identify SNPs within high-LD regions:

```bash
./ldak.out --cut-genes highld --bfile human --genefile highld.fake
```

This command locates matching SNPs and saves results to `highld/genes.predictors.used`.

---

**Site:** DougSpeed.com – The Home of LDAK
**Platform:** WordPress
