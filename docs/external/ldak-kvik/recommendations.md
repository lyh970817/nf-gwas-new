# LDAK-KVIK Recommendations

## Analysing Imputed Data

When datasets contain over one million predictors, Step 1 can become slow. To optimize performance, restrict Step 1 to approximately 500,000 predictors while continuing to use all predictors in Step 2 for association analysis.

### Creating SNP Subsets

You can use existing predictor subsets (directly-genotyped SNPs or quality-controlled variants) or create new ones through moderate thinning. For SNP data, the suggested approach identifies variants with MAF > 0.01 and filters to eliminate predictors within 100kb with squared correlation exceeding 0.5.

**Command for thinning:**
```bash
./ldak6.1.linux --thin-common thin --bfile data --max-threads 4
```

**Restrict Step 1 using extracted SNPs:**
```bash
./ldak6.1.linux --kvik-step1 kvik --bfile data --pheno phenofile --covar covfile \
  --extract thin.in --max-threads 4
```

**Important note:** Using 500,000 to 1 million SNPs in Step 1 balances statistical power with computational efficiency. Further reduction compromises detection power and is discouraged.

## Genotype Data Format

> "LDAK accepts genotype data of both `.bed` format (using flag `--bfile`) and `.bgen` format (using flag `--bgen` and `--sample`), however, LDAK processes `.bed` files faster than `.bgen` files due to simpler genotype coding."

Converting `.bgen` files to `.bed` format before analysis optimizes runtime. Though this hardcodes dosage values and loses some information, results remain highly comparable.

## Parallelization

Users can specify thread numbers to parallelize algorithm components:

```bash
./ldak6.1.linux --kvik-step1 kvik --bfile data --pheno phenofile --covar covfile \
  --max-threads 16
```

**Cost consideration:** Performance gains from multiple threads are limited. For cloud-based analyses incurring additional costs, 4 or fewer threads are recommended.

## Analysing Multiple Phenotypes

### Input Format

Phenotype files require FID and IID columns followed by phenotypic values:

```
FID IID Pheno1 Pheno2 Pheno3
1 1 0.25 25 14
2 2 0.42 12 2
3 3 0.32 36 38
```

### Specification Flags

Use `--mpheno` to select individual phenotypes or `--mpheno ALL` to process simultaneously during Steps 1-2, reducing computational demands:

```bash
./ldak6.1.linux --kvik-step1 kvik --bfile data --pheno phenofile --covar covfile \
  --mpheno ALL --max-threads 4

./ldak6.1.linux --kvik-step2 kvik --bfile data --pheno phenofile --covar covfile \
  --mpheno ALL --max-threads 4
```

Results appear as `kvik.step2.pheno1.assoc`, `kvik.step2.pheno2.assoc`, etc.

### Gene-based Analysis

Step 3 cannot run simultaneously for all phenotypes and requires individual processing:

```bash
for i in {1..10}; do
  ./ldak6.1.linux --cut-genes kvik_gbat_${i} --bfile data \
    --genefile RefSeq_GRCh38.txt --max-threads 4
  ./ldak6.1.linux --calc-genes-reml kvik_gbat_${i} --bfile data \
    --summary kvik.step2.pheno${i}.summaries --power -0.25 \
    --max-threads 4 --allow-ambiguous YES
  ./ldak6.1.linux --join-genes-reml kvik_gbat_${i}
done
```

Results save to `kvik_gbat_${i}/remls.all`.

## Analysing Small Sample Sizes

Although LDAK-KVIK targets datasets exceeding 50,000 samples, smaller datasets remain valid. Mixed-model benefits diminish with smaller samples due to less accurate LOCO PRS construction in Step 1. However, LDAK-KVIK maintains type 1 error control in highly related populations, where classical regression would show inflation.

### Alternative Regression Methods

**Linear regression:**
```bash
./ldak6.1.linux --linear kvik --bfile data --pheno phenofile --covar covfile \
  --max-threads 4
```

**Logistic regression (with saddlepoint approximation by default):**
```bash
./ldak6.1.linux --logistic kvik --bfile data --pheno phenofile --covar covfile \
  --max-threads 4
```

For binary traits, the saddlepoint approximation addresses inflation from case-control imbalance.
