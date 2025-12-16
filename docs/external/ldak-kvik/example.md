# LDAK-KVIK Example Code

LDAK-KVIK enables rapid mixed-model association testing for genome-wide association studies.

## Simulating Test Data

### Generating Genotypes

Create synthetic SNP data:

```bash
./ldak6.1.linux --make-snps data --num-samples 10000 --num-snps 50000
```

This produces three files (`data.bed`, `data.bim`, `data.fam`) containing genetic information for 10,000 individuals across 50,000 variants. The SNPs are distributed evenly across 22 chromosomes with random minor allele frequencies between 0 and 0.5.

### Generating Quantitative Phenotypes

Create a simulated trait:

```bash
./ldak6.1.linux --make-phenos pheno --bfile data --power -0.25 --her 0.5 \
  --num-phenos 1 --num-causals 1000
```

This generates one phenotype with 50% SNP heritability influenced by 1,000 causal variants. The power parameter (-0.25) reflects that common variants typically explain more variance.

### Generating Binary Phenotypes

For case-control traits:

```bash
./ldak6.1.linux --make-phenos pheno --bfile data --power -0.25 --her 0.5 \
  --num-phenos 1 --num-causals 1000 --prevalence 0.2
```

This produces a binary phenotype with 20% case prevalence and 50% liability heritability.

## Running LDAK-KVIK

LDAK-KVIK executes in three sequential steps:

### Step 1: LOCO PRS Computation

Computes Leave-One-Chromosome-Out (LOCO) polygenic risk scores using Elastic Net regression:

```bash
./ldak6.1.linux --kvik-step1 kvik --bfile data --pheno pheno.pheno \
  --covar data.covar --max-threads 2
```

### Step 2: Single-SNP Analysis

Performs single-SNP association analysis using LOCO PRS as offset:

```bash
./ldak6.1.linux --kvik-step2 kvik --bfile data --pheno pheno.pheno \
  --covar data.covar --max-threads 2
```

### Step 3: Gene-Based Analysis

Conducts gene-based association testing:

```bash
./ldak6.1.linux --kvik-step3 kvik --bfile data \
  --genefile RefSeq_GRCh38.txt --max-threads 2
```

## Binary Trait Analysis

For case-control phenotypes, add `--binary YES` in Step 1:

```bash
./ldak6.1.linux --kvik-step1 kvik --bfile data --pheno pheno.pheno \
  --covar data.covar --binary YES --max-threads 2
```

The binary trait designation automatically carries forward to Step 2.
