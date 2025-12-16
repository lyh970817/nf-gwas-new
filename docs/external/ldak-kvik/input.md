# LDAK-KVIK Data Format Guide

LDAK requires genotypes and phenotypes as core inputs, with optional covariates and gene annotations.

## Genotype Formats

LDAK accepts genetic data through three distinct approaches:

| Format | Argument | Requirements |
|--------|----------|--------------|
| Binary PLINK | `--bfile` | Requires `.bed`, `.bim`, `.fam` files; supports hard-coded SNP genotypes |
| Oxford | `--bgen` | Requires associated sample file specified via `--sample` flag; accommodates dosage values |
| SP Format | `--sp` | Requires `.sp`, `.bim`, `.fam` files in text matrix format |

**Key Limitation:** "LDAK is not able to process data of `pgen` format and `vcf` format." Users should convert these to Binary PLINK format first.

**Data Type Note:** Standard SNP data contains predictor values between 0-2 (representing A1 allele count). For alternative datatypes, use BED or SP format with `--SNP-data NO` flag.

## Phenotype Specifications

Phenotype files follow PLINK formatting with these requirements:

- First two columns: Family ID (FID) and Individual ID (IID)
- Subsequent columns: Phenotype values
- Optional header with "FID IID" or "ID1 ID2" labels

**Example Structure:**
```
FID IID Pheno1 Pheno2
1   1   0.25   25
2   2   0.42   12
3   3   0.32   36
```

**Multiple Phenotype Handling:** Specify the target phenotype using `--mpheno <integer>` or use `--mpheno -1` for functions supporting all phenotypes.

**Missing Data:** Denote missing values as "NA". When analyzing single phenotypes, samples with NA values are excluded. Multiple phenotype analyses impute NA values to mean.

**Binary Phenotype Values:**
- 0 (control), 1 (case), or NA
- 1 (control), 2 (case), or NA

## Covariate Files

Covariates follow PLINK format with FID and IID in leading columns:

```
FID IID PC1    PC2    PC3    Age Sex
1   1   0.42   -0.12  1.23   41  0
2   2   -0.1   0.23   0.49   64  1
3   3   0.21   -0.14  -0.23  27  0
```

**Classification:**
- Quantitative covariates: `--covar`
- Categorical covariates: `--factors`

**Covariate Selection:**
- Quantitative: `--covar-numbers 1,2,4-6,8` (comma/dash syntax)
- Named: `--covar-names` (requires header labels)

**Missing Values:** Replace NA values with corresponding covariate mean.

## Gene Annotations

Gene-based analysis requires Browser Extensible Data format with one row per gene containing:
1. Gene name
2. Chromosome
3. Start basepair
4. End basepair

**Example:** "ABC 7 0 10" indicates gene ABC spanning basepairs 0-10 on Chromosome 7.

**Download Resources:**
```bash
wget https://dougspeed.com/wp-content/uploads/RefSeq_GRCh37.txt
wget https://dougspeed.com/wp-content/uploads/RefSeq_GRCh38.txt
```

## Data Filtering Options

### SNP/Predictor Filtering

| Argument | Function |
|----------|----------|
| `--extract <file>` | Retain specified predictors only |
| `--exclude <file>` | Remove specified predictors (takes priority over extract) |
| `--chr <integer>` | Use specific chromosome; `--chr AUTO` selects autosomes (1-22) |
| `--snp <name>` | Use single named predictor |

### Sample Filtering

| Argument | Function |
|----------|----------|
| `--keep <file>` | Retain specified samples only |
| `--remove <file>` | Exclude specified samples (takes priority over keep) |
| `--pheno <file>` | Include only samples with available phenotypes |

**Important:** Filtering by minor allele frequency, variance, missingness, or information score requires data remake and cannot occur dynamically.
