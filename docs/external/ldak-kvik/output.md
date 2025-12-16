# LDAK-KVIK Output

LDAK-KVIK generates output files across three analysis steps.

## Step 1 Output Files

Step 1 produces five files:

| File | Purpose |
|------|---------|
| `kvik.step1.progress` | Screen output log |
| `kvik.step1.root` | Input arguments for downstream steps |
| `kvik.step1.loco.details` | Scaling estimates, power parameters, heritability values |
| `kvik.step1.loco.prs` | Leave-one-chromosome-out predictors using elastic net |
| `kvik.step1.effects` | SNP effects from full elastic net model |

### kvik.step1.loco.details Format

Contains per-chromosome information:
- Lambda scaling factor
- Power parameter estimate
- Heritability estimate
- Number of SNPs used

## Step 2 Output Files

Step 2 performs single-SNP analysis using Step 1 PRS as offset.

### Output Files Generated

| File | Purpose |
|------|---------|
| `kvik.step2.progress` | Verbose log |
| `kvik.step2.coeff` | Fitted regression coefficients for covariates |
| `kvik.step2.pvalues` | P-values per SNP |
| `kvik.step2.summaries` | Z-scores per SNP |
| `kvik.step2.assoc` | Complete summary statistics |

### kvik.step2.assoc Column Specifications

| Column | Description |
|--------|-------------|
| `Chromosome` | Chromosome number |
| `Predictor` | SNP identifier |
| `Basepair` | Base pair position |
| `A1` | Effect allele |
| `A2` | Other allele |
| `Wald_Stat` | Z-scores |
| `Wald_P` | Associated P-values |
| `Effect` | Regression coefficients |
| `SD` | Standard errors |
| `A1_mean` | Mean frequency of allele 1 |
| `MAF` | Minor allele frequency |
| `SPA_Status` | Saddlepoint approximation application indicator |

## Step 3 Output Files

Step 3 performs gene-based association analysis.

### kvik.step3.remls.all Columns

| Column | Description |
|--------|-------------|
| `Gene_Name` | Gene identifier |
| `Gene_Chr` | Chromosome location |
| `Gene_Start` | Start position |
| `Gene_End` | End position |
| `Length` | Number of SNPs in gene |
| `Heritability` | Heritability estimate |
| `SD` | Standard deviation |
| `Null_Likelihood` | Null model likelihood |
| `Alt_Likelihood` | Alternative model likelihood |
| `LRT_Stat` | Likelihood ratio test statistic |
| `LRT_P_Raw` | Raw P-value |
| `LRT_P_Perm` | Permutation-corrected P-value |

## Multiple Phenotype Output

When using `--mpheno ALL`, results are saved with phenotype-specific suffixes:
- `kvik.step2.pheno1.assoc`
- `kvik.step2.pheno2.assoc`
- etc.
