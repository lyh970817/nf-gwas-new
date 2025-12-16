# Running LDAK-KVIK on UK Biobank RAP

This guide covers executing LDAK-KVIK on the UK Biobank Research Analysis Platform (UKB-RAP).

## Execution Methods

### Swiss-Army-Knife Approach

The platform offers the Swiss-Army-Knife tool, which sends command-line executables to the RAP server for background processing. This approach is recommended for computationally intensive analyses.

### Cloud Workstation Alternative

LDAK-KVIK commands can also be executed directly on the Cloud Workstation, where users establish a virtual environment to download, analyze UKB data, and upload results.

## Running LDAK-KVIK Step 1

**Purpose:** Generate polygenic risk scores using directly genotyped SNPs.

**Rationale:** Including imputed SNPs does not improve accuracy of Step 1 results, and restricting to directly genotyped SNPs accelerates computation.

```bash
project="Basic GWAS"
data_file_dir="data"

run_ldak="wget https://github.com/dougspeed/LDAK/raw/refs/heads/main/ldak6.1.linux; \
  chmod a+x ldak6.1.linux; \
  ./ldak6.1.linux --kvik-step1 kvik --bfile ukb_merged \
    --pheno data_height_tab --covar data_pcs_tab --max-threads 4"

dx run swiss-army-knife \
  -iin="${data_file_dir}/ukb_merged.bed" \
  -iin="${data_file_dir}/ukb_merged.bim" \
  -iin="${data_file_dir}/ukb_merged.fam" \
  -iin="${data_file_dir}/data_height_tab" \
  -iin="${data_file_dir}/data_pcs_tab" \
  -icmd="${run_ldak}" --tag="kvik_step1" \
  --instance-type "mem3_ssd1_v2_x4" \
  --destination="${project}:${data_file_dir}"
```

**Output:** Files prefixed with `kvik.step1`, including LOCO PRS estimates and root files.

## Running LDAK-KVIK Step 2

Step 2 can process chromosomes separately or use combined genotype files. Accepts both `.bed` (via `--bfile`) and `.bgen` formats (via `--bgen` and `--sample`).

### Per-Chromosome Processing

```bash
project="Basic GWAS"
data_file_dir="data"

for i in {1..22}; do
  run_ldak="chmod a+x ldak6.1.linux ; \
    ./ldak6.1.linux --kvik-step2 kvik --bfile imp_chr${i} \
      --pheno data_height_tab --covar data_pcs_tab \
      --keep ukb_merged.fam --max-threads 4"

  dx run swiss-army-knife \
    -iin="data_height_tab" \
    -iin="data_pcs_tab" \
    -iin="${data_file_dir}/ukb_merged.fam" \
    -iin="${data_file_dir}/imp_chr${i}.bed" \
    -iin="${data_file_dir}/imp_chr${i}.bim" \
    -iin="${data_file_dir}/imp_chr${i}.fam" \
    -iin="${data_file_dir}/kvik.step1.loco.details" \
    -iin="${data_file_dir}/kvik.step1.loco.prs" \
    -iin="${data_file_dir}/kvik.step1.effects" \
    -iin="${data_file_dir}/kvik.step1.root" \
    -iin="${data_file_dir}/ldak6.1.linux" \
    -icmd="${run_ldak}" --tag="kvik_step2" \
    --instance-type "mem1_ssd1_v2_x16" \
    --destination="${project}:${data_file_dir}" \
    --brief --yes
done
```

**Output:** Chromosome-specific GWAS results with `kvik.step2.chr<number>` prefix.

## Merging Output Files

When analyzing chromosomes separately, merge results using Python in JupyterLab:

```python
import pandas as pd
import glob
import dxpy

# Identify files
file_pattern = "/mnt/project/data/kvik.step2.chr*.assoc"
file_list = glob.glob(file_pattern)

# Read and append
dataframes = []
for file in file_list:
    df = pd.read_table(file)
    dataframes.append(df)

# Concatenate and write
merged_data = pd.concat(dataframes, ignore_index=True)
merged_data.to_csv("kvik.assoc", sep='\t', index=False)
```

Upload results:
```bash
dx upload kvik.assoc --path project/kvik.assoc
```

## Step 3: Gene-Based Analysis

For gene-based analysis, run Step 3 after merging Step 2 results:

```bash
run_ldak="./ldak6.1.linux --kvik-step3 kvik --bfile ukb_merged \
  --genefile RefSeq_GRCh38.txt --max-threads 4"

dx run swiss-army-knife \
  -iin="${data_file_dir}/ukb_merged.bed" \
  -iin="${data_file_dir}/ukb_merged.bim" \
  -iin="${data_file_dir}/ukb_merged.fam" \
  -iin="${data_file_dir}/kvik.step2.summaries" \
  -iin="${data_file_dir}/RefSeq_GRCh38.txt" \
  -iin="${data_file_dir}/ldak6.1.linux" \
  -icmd="${run_ldak}" --tag="kvik_step3" \
  --instance-type "mem1_ssd1_v2_x8" \
  --destination="${project}:${data_file_dir}"
```
