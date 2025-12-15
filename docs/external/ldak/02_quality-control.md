# Quality Control

## Overview

Before conducting heritability analysis, thorough quality control of samples and predictors is essential. Heritability analyses are particularly sensitive to genotyping errors because errors accumulate across many predictors, potentially creating substantial overall bias. Additionally, population structure and familial relatedness can inflate estimates by introducing correlations between predictors and phenotypes that reflect ancestry rather than causality.

Quality control is equally critical when building prediction models, as genotyping errors, population structure, and familial relatedness can bias effect size estimates, reducing model performance on independent samples.

---

## Sample Filtering Guidelines

### Population Structure

The goal is to obtain an ancestrally homogeneous, unrelated sample set. The recommended approach involves:

1. Identifying common SNPs (MAF > 0.01) with high quality (information score > 0.95, missingness < 0.01) and autosomal location
2. Computing a kinship matrix using a global reference dataset, restricting to these SNPs in approximate linkage equilibrium
3. Performing principal component analysis to identify ancestry axes
4. Projecting study samples onto these axes to exclude ancestral outliers

### Relatedness Filtering

After removing ancestry outliers:

1. Create a kinship matrix using the main dataset
2. Remove samples until no pair exceeds the smallest observed kinship value (default filtering behavior in LDAK)

---

## Predictor Filtering Guidelines

### Minor Allele Frequency

Most heritability and prediction analyses focus on common variants (MAF > 0.01 or > 0.005), as methodology for rare variants remains unclear. Rare variants are excluded from prediction models because effect sizes cannot be accurately estimated.

### SNP Quality

Imputation information score is the preferred quality metric, reflecting how closely observed genotypes match expected values. Standard thresholds:

- Information score > 0.95 or > 0.99
- Filtering by missingness or Hardy-Weinberg equilibrium is generally unnecessary for common SNPs

### Chromosomal Restriction

Analyses typically restrict to autosomal predictors, as sex chromosome inclusion requires specialized handling.

---

## Testing for Inflation

### Population Structure and Familial Relatedness

Calculate: **T1 = (h²A + h²B + h²C + h²D − h²SNP) / 3**

Where h²A, h²B, h²C, h²D represent heritability estimates from genome quarters, and h²SNP is the whole-genome estimate.

If samples are unrelated with no population structure, T1 should be near zero. Positive values indicate SNPs are correlated across chromosomes due to structure or relatedness, causing each quarter to capture heritability from other regions.

Obtain estimates using REML or Haseman-Elston Regression. Test significance empirically by sampling from the estimated distributions.

### Genotyping Errors (Batch-Based Analysis Only)

Calculate: **T2 = h²Same − h²Diff**

Where h²Same and h²Diff are heritability estimates calculated across sample pairs in the same genotyping batch versus different batches.

Genotyping errors make samples in the same batch appear more similar genetically. If same-batch sample pairs are also more phenotypically similar, h²Same will exceed h²Diff, producing positive T2 values.

Obtain estimates using Haseman-Elston or PCGC Regression with subset options.

---

## Practical Example Workflow

### Step 1: Filter Based on Population Structure

Create kinship matrix from global reference data, restricted to SNPs in the main dataset:

```bash
awk < human.bim '{print $2}' > human.snps
./ldak.out --thin hapmap --bfile hapmap --window-prune .05 --window-cm 1 --extract human.snps
./ldak.out --calc-kins-direct hapmap --bfile hapmap --power -1 --extract hapmap.in
```

Perform PCA and obtain loadings:

```bash
./ldak.out --pca hapmap --grm hapmap --axes 20
./ldak.out --calc-pca-loads hapmap --pcastem hapmap --grm hapmap --bfile hapmap
```

Project main dataset:

```bash
./ldak.out --calc-scores hapmap --scorefile hapmap.load --bfile human --power 0
```

Identify outliers from projections and save to outliers.ind file.

### Step 2: Filter Based on Relatedness

Create kinship matrix from main dataset excluding outliers:

```bash
./ldak.out --calc-kins-direct human --bfile human --power -1 --extract hapmap.in --remove outliers.ind
./ldak.out --filter human --grm human
```

The command generates human.keep and human.lose files listing retained and removed samples.

### Step 3: Test for Structure and Relatedness Inflation

Create chromosome-specific kinship matrices:

```bash
./ldak.out --calc-kins-direct chr21.clean --bfile human --power -.25 --chr 21 --remove outliers.ind
./ldak.out --calc-kins-direct chr22.clean --bfile human --power -.25 --chr 22 --remove outliers.ind
```

Estimate heritability separately and combined:

```bash
./ldak.out --reml chr21.clean --grm chr21.clean --pheno quant.pheno --keep human.keep
./ldak.out --reml chr22.clean --grm chr22.clean --pheno quant.pheno --keep human.keep

echo "chr21.clean
chr22.clean" > both.txt
./ldak.out --reml both --mgrm both.txt --pheno quant.pheno --keep human.keep
```

Compare estimates using the R sampling approach provided in the testing section above.

### Step 4: Test for Genotyping Error Inflation

Create overall kinship matrix:

```bash
./ldak.out --calc-kins-direct HumDef.clean --bfile human --power -.25 --remove outliers.ind
```

Run HE regression with batch subsets:

```bash
./ldak.out --he batch --pheno quant.pheno --grm HumDef.clean --subset-prefix ind --subset-number 2 --keep human.keep
```

Compare results in batch.he, batch.he.within, and batch.he.across output files.

---

## Important Considerations

- Thresholds provided are suggestions; evaluate appropriateness for your specific dataset
- For UK Biobank, an information score threshold of 0.95 was used, but adjust based on your data distribution
- The test datasets contain ancestral outliers and related samples; ideally exclude outliers from all analyses and related samples from heritability estimation
- Quality control effectiveness can be verified through the inflation tests described above
