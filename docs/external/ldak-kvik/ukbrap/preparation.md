# LDAK-KVIK Data Preparation for UK Biobank RAP

This tutorial covers preparing data for LDAK-KVIK analysis on the UK Biobank Research Analysis Platform (UKB-RAP).

## Prerequisites

Before beginning data preparation:

1. Install the [dx-toolkit](https://documentation.dnanexus.com/downloads)
2. Have a RAP project with dispensed data
3. Authenticate using `dx login`
4. Create a working directory: `dx mkdir data`

## Phenotype Preparation

### Extracting Phenotype Data

Use the `dx extract_dataset` command to retrieve phenotype fields from Bulk data:

```bash
dx extract_dataset [app_id].dataset \
  --fields "participant.eid,participant.eid,participant.p50_i0" \
  -o "data_height"
```

This extracts participant ID and height measurements. Add additional phenotypes by expanding the `--fields` parameter.

View all available phenotypes:
```bash
dx extract_dataset [app_id].dataset --list-fields
```

### Converting to PLINK Format

Convert comma-separated output to tab-separated PLINK format with proper NA coding:

```bash
sed -i '1s/.*/FID,IID,Pheno/' data_height
sed -E 's/(^|,)(,|$)/\1NA\2/g' data_height | \
  sed -E 's/(^|,)(,|$)/\1NA\2/g' | \
  awk 'gsub(",","\t",$0)' > data_height_tab
```

### Uploading to RAP

```bash
dx upload "data_height_tab"
```

## Covariate Preparation

### Principal Components Extraction

Extract the top ten principal components:

```bash
dx extract_dataset [app_id].dataset \
  --fields "participant.eid,participant.eid,participant.p22009_a1,participant.p22009_a2,participant.p22009_a3,participant.p22009_a4,participant.p22009_a5,participant.p22009_a6,participant.p22009_a7,participant.p22009_a8,participant.p22009_a9,participant.p22009_a10" \
  -o "data_pcs"
```

### Formatting Covariates

```bash
sed -i '1s/.*/FID,IID,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10/' data_pcs
sed -E 's/(^|,)(,|$)/\1NA\2/g' data_pcs | \
  sed -E 's/(^|,)(,|$)/\1NA\2/g' | \
  awk 'gsub(",","\t",$0)' > data_pcs_tab
dx upload "data_pcs_tab"
```

Useful covariates include: sex, age, principal components, and phenotype-relevant predictors.

## Genotype Preparation

### Directly Genotyped Data (Step 1)

Merge chromosome-specific files using Swiss-Army-Knife with quality control:

```bash
data_field="22418"
project="Basic GWAS"
data_file_dir="data"

run_merge="cp /mnt/project/Bulk/Genotype\ Results/Genotype\ calls/ukb${data_field}_c{1..22}_b0_v2.{bed,bim,fam} . ; \
  ls *bed | sed -e 's/.bed//g' > files_to_merge.txt ; \
  plink --merge-list files_to_merge.txt --make-bed --maf 0.01 --mind 0.1 --geno 0.1 \
    --hwe 1e-15 --out ukb_merged"

dx run swiss-army-knife \
  -icmd="${run_merge}" \
  --instance-type "mem1_ssd1_v2_x16" \
  --destination="${project}:${data_file_dir}"
```

### Imputed Data (Step 2)

Process imputed genotypes for each chromosome with quality control filters:

```bash
file_dir="/Bulk/Imputation/UKB imputation from genotype"
data_field="22828"
project="Basic GWAS"
data_file_dir="data"

for i in {1..22}; do
  run_plink_bgen="plink2 --bgen ukb${data_field}_c${i}_b0_v3.bgen 'ref-first' \
    --sample ukb${data_field}_c${i}_b0_v3.sample \
    --maf 0.001 --mac 20 --geno 0.1 --hwe 1e-15 --mind 0.1 --rm-dup 'force-first' \
    --make-bed --out imp_chr${i}"

  dx run swiss-army-knife \
    -iin="${file_dir}/ukb${data_field}_c${i}_b0_v3.bgen" \
    -iin="${file_dir}/ukb${data_field}_c${i}_b0_v3.bgen.bgi" \
    -iin="${file_dir}/ukb${data_field}_c${i}_b0_v3.sample" \
    -icmd="${run_plink_bgen}" --tag="make_bed" \
    --instance-type "mem1_ssd1_v2_x36" \
    --destination="${project}:${data_file_dir}" --brief --yes
done
```

**Note:** The guide converts `.bgen` format to `.bed` for faster analysis. Alternatively, use `--write-snplist` and `--write-samples` to generate cleaned SNP and sample lists for use with original .bgen files.

## Alternative Approaches

These steps can also be implemented via:
- R, Python, or Bash scripts in JupyterLab
- Cloud Workstation virtual environment

Both provide interactive alternatives to the CLI method described above.
