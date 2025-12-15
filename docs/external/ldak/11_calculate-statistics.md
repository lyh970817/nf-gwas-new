# Calculate Statistics

## Overview

LDAK can compute basic metrics (e.g., allele frequencies and missing rates) for genetic data files. These can subsequently be used as part of Quality Control.

Always read the screen output, which suggests arguments and estimates memory usage.

---

## Main Argument

The primary argument is `--calc-stats <outfile>`.

### Required Option

- `–bfile/–gen/–sp/–speed <prefix>` or `--bgen <datafile>` - to specify genetic data files (see [File Formats](http://dougspeed.com/file-formats/))

### Output Files

The output file `<outfile>.stats` contains:
- Observed frequency of the A1 allele
- MAF (Minor Allele Frequency)
- Call rate for each SNP
- Information scores (if data files provide SNP probabilities)

The output file `<outfile>.missing` contains:
- Missing rates for each individual
- Heterozygosity rates for each individual

---

## Example

Using the binary PLINK files human.bed, human.bim and human.fam from the [Test Datasets](http://dougspeed.com/test-datasets/):

```
./ldak.out --calc-stats stats --bfile human
```

The metrics are stored in `stats.stats` and `stats.missing`.

---

**Site:** [DougSpeed.com](https://dougspeed.com/) - The Home of LDAK
