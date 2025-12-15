# Make Data

## Overview

LDAK enables conversion between genetic data file formats, merging multiple datasets, and reducing data through sample or predictor subsetting. The screen output provides helpful suggestions and memory usage estimates.

## Output Format Options

The primary argument determines the output data format:

- `--make-bed <outfile>` — Binary PLINK format
- `--make-sp <outfile>` — Original SP format
- `--make-sped <outfile>` — Old binary SP format
- `--make-speed <outfile>` — New binary SP format
- `--make-gen <outfile>` — Gen format

See [Genetic Data Formats](http://dougspeed.com/file-formats/) for detailed specifications.

## Input Data Specification

**Single dataset:** Use one of these flags:
- `--bfile <datastem>`
- `--bgen <datafile>`
- `--gen <datastem>`
- `--sp <datastem>`
- `--sped <datastem>`
- `--speed <datastem>`

**Multiple datasets:** Use the corresponding multi-file flags with a data list file:
- `--mbfile <datalist>`
- `--mgen <datalist>`
- `--msp <datalist>`
- `--msped <datalist>`
- `--mspeed <datalist>`

The list file typically contains three columns: predictor file names, annotation files, and sample annotation files.

## Genotype Conversion

When converting genotype probabilities to hard genotypes (e.g., BGEN to BED format), use:
- `--threshold 0.9` — Computes dosage and maps to nearest integer
- `--min-prob 0.9` — Uses genotype with probability above threshold

## Predictor Filtering Options

Filter predictors using these parameters:
- `--min-maf <float>` — Minimum minor allele frequency (SNP data only)
- `--max-maf <float>` — Maximum minor allele frequency (SNP data only)
- `--min-var <float>` — Minimum variance
- `--min-obs <float>` — Minimum proportion of non-missing values
- `--min-info <float>` — Information score (for genotype probability data)

## Sample Subsetting

- `--keep <keepfile>` — Retain specified samples
- `--remove <removefile>` — Exclude specified samples

## Predictor Subsetting

- `--extract <extractfile>` — Include specified predictors
- `--exclude <excludefile>` — Exclude specified predictors
- `--chr <integer>` — Restrict to chromosome
- `--snp <predname>` — Specific predictor name

See [Data Filtering](http://dougspeed.com/data-filtering/) for additional details.

## Encoding Options

Default SNP values: 0/1/2 (count of A1 alleles, or NA if missing)

Alternative encodings:
- `--encoding DOM` — Dominant (0/2/2)
- `--encoding REC` — Recessive (0/0/2)
- `--encoding HET` — Heterozygote (0/2/0)
- `--encoding MINOR` — Minor allele as A1
- `--encoding MISS` — Indicates NA status

## Example Usage

**Convert Binary PLINK to SP format:**

```
./ldak.out --make-sp human.sp --bfile human
```

Output files: human.sp.sp, human.sp.bim, human.sp.bim (SP format text file readable from binary formats)

**Convert Binary PLINK to SPEED format:**

```
./ldak.out --make-speed human.speed --bfile human
```

Output files: human.speed.speed, human.speed.bim, human.speed.bim

---

*Website:* [DougSpeed.com](https://dougspeed.com/)
*Powered by:* [WordPress](https://wordpress.org/)
