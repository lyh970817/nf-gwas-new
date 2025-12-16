# nf-gwas

[![Nextflow](https://img.shields.io/badge/Nextflow-DSL2-brightgreen)](https://www.nextflow.io/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A comprehensive Nextflow-based pipeline for genome-wide association studies (GWAS) and genetic analyses. nf-gwas enables researchers to perform association testing, heritability estimation, genetic correlation analysis, and causal inference using state-of-the-art statistical methods.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Analysis Types](#analysis-types)
- [Input Data](#input-data)
- [Usage Examples](#usage-examples)
- [Output Files](#output-files)
- [Configuration](#configuration)
- [Workflows](#workflows)
- [Troubleshooting](#troubleshooting)
- [Citation](#citation)

---

## Features

- **Multiple Analysis Types**: Association testing, heritability estimation, genetic correlation, and causal inference
- **Flexible Tool Support**: REGENIE, GCTA, LDAK, BOLT-LMM, LAVA, and LCV
- **Scalable**: Designed for biobank-scale datasets (100k+ samples)
- **Reproducible**: Containerized execution via Docker/Singularity
- **Parallel Processing**: Automatic chromosome-level parallelization
- **Multiple Input Formats**: VCF, PLINK1 (bed/bim/fam), PLINK2 (pgen/psam/pvar)

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/genepi/nf-gwas.git
cd nf-gwas

# Build Singularity container
singularity build nf-gwas.sif nf-gwas.def

# Run with test data
nextflow run main.nf -profile test,singularity
```

---

## Installation

### Requirements

- **Nextflow**: >= 22.10.4
- **Container Runtime**: Docker or Singularity (recommended for HPC)
- **Memory**: Depends on analysis type and sample size (see individual workflows)

### Setup

1. **Install Nextflow**:
   ```bash
   curl -s https://get.nextflow.io | bash
   mv nextflow ~/bin/  # Or any directory in your PATH
   ```

2. **Build Container**:
   ```bash
   # Singularity (recommended for HPC)
   singularity build nf-gwas.sif nf-gwas.def

   # Or use Docker
   docker build -t nf-gwas .
   ```

3. **Verify Installation**:
   ```bash
   nextflow run main.nf -profile test,singularity
   ```

---

## Analysis Types

nf-gwas supports four primary types of genetic analyses:

### 1. Association Analysis

Identify genetic variants associated with traits or diseases.

| Method | Tool | Best For | Speed |
|--------|------|----------|-------|
| Two-step regression | REGENIE | Large biobanks, gene-based tests | Fast |
| Mixed model | GCTA FastGWA | Alternative to REGENIE | Fast |
| Mixed model | LDAK-KVIK | Best power/speed trade-off | Fastest |

### 2. Heritability Estimation

Quantify the proportion of phenotypic variance explained by genetics.

| Method | Tool | Data Type | Speed |
|--------|------|-----------|-------|
| GREML | GCTA | Individual-level | Slow (gold standard) |
| GREML-LDMS | GCTA | Individual-level | Slow (partitioned h²) |
| REML | LDAK | Individual-level | Medium |
| HE Regression | LDAK | Individual-level | Fast (large N) |
| PCGC | LDAK | Individual-level (binary) | Medium |
| SumHer | LDAK | Summary statistics | Fast |
| REML | BOLT-LMM | Individual-level | Fast |

### 3. Genetic Correlation

Estimate shared genetic architecture between traits.

| Method | Tool | Data Type |
|--------|------|-----------|
| SumCors | LDAK | Summary statistics |
| Bivariate GREML | GCTA | Individual-level |
| Local rg | LAVA | Summary statistics |

### 4. Causal Inference

Infer genetically causal relationships between traits.

| Method | Tool | Data Type |
|--------|------|-----------|
| LCV | LCV | Summary statistics |

---

## Input Data

### Required Files

| File Type | Description | Example |
|-----------|-------------|---------|
| **Genotypes** | VCF or PLINK format | `chr*.vcf.gz`, `data.{bed,bim,fam}` |
| **Phenotypes** | Tab-separated file with FID, IID, traits | `phenotypes.txt` |

### Optional Files

| File Type | Description | Example |
|-----------|-------------|---------|
| **Covariates** | Tab-separated file with FID, IID, covariates | `covariates.txt` |
| **Summary Statistics** | GWAS results for summary-based methods | `gwas_results.txt` |

### File Format Details

**Phenotype File**:
```
FID    IID    height    bmi    disease
1001   1001   175.5     24.3   0
1002   1002   162.3     22.1   1
```

**Covariate File**:
```
FID    IID    age    sex    PC1       PC2
1001   1001   45     1      0.012    -0.008
1002   1002   52     2      0.003     0.015
```

**Summary Statistics** (for SumHer/SumCors):
```
SNP         A1    A2    N       BETA     SE       P
rs12345     A     G     50000   0.023    0.005    4.2e-6
rs67890     C     T     50000  -0.015    0.004    1.8e-4
```

---

## Usage Examples

### Association Analysis

**REGENIE (Recommended for large datasets)**:
```bash
nextflow run main.nf \
    --project my_gwas \
    --run_association_analysis true \
    --genotypes_association_vcf "data/chr*.vcf.gz" \
    --genotypes_prediction "data/array.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height,bmi \
    --covariates_filename covariates.txt \
    --covariates_columns age,sex,PC1,PC2 \
    -profile slurm,singularity
```

**LDAK-KVIK (Fastest)**:
```bash
nextflow run main.nf \
    --project my_gwas \
    --run_association_analysis true \
    --association_method ldak_kvik \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height \
    -profile slurm,singularity
```

### Heritability Estimation

**GCTA GREML (Gold standard)**:
```bash
nextflow run main.nf \
    --project heritability \
    --run_heritability_estimation true \
    --heritability_method gcta_greml \
    --genotypes_association_plink2 "data/chr*.{pgen,psam,pvar}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height \
    -profile singularity
```

**LDAK HE (Fast, for large N)**:
```bash
nextflow run main.nf \
    --project heritability \
    --run_heritability_estimation true \
    --heritability_method ldak_he \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns height \
    -profile singularity
```

**LDAK PCGC (Binary traits)**:
```bash
nextflow run main.nf \
    --project heritability_case_control \
    --run_heritability_estimation true \
    --heritability_method ldak_pcgc \
    --ldak_pcgc_prevalence 0.05 \
    --genotypes_association_plink1 "data/chr*.{bed,bim,fam}" \
    --phenotypes_filename phenotypes.txt \
    --phenotypes_columns disease \
    --phenotypes_binary_trait true \
    -profile singularity
```

**SumHer (From summary statistics)**:
```bash
nextflow run main.nf \
    --project sumher_analysis \
    --run_heritability_estimation true \
    --heritability_method ldak_sumher \
    --ldak_sumher_summary_stats gwas_results.txt \
    --ldak_sumher_tagfile tagging_file.tagging \
    -profile singularity
```

### Genetic Correlation

**LDAK SumCors (Summary statistics)**:
```bash
nextflow run main.nf \
    --project genetic_correlation \
    --run_genetic_correlation true \
    --genetic_correlation_method ldak_sumcors \
    --ldak_sumcors_summary_stats1 trait1_gwas.txt \
    --ldak_sumcors_summary_stats2 trait2_gwas.txt \
    --ldak_sumcors_tagfile tagging_file.tagging \
    -profile singularity
```

**LAVA Local rg (Local genetic correlation)**:
```bash
nextflow run main.nf \
    --project local_rg \
    --run_genetic_correlation true \
    --genetic_correlation_method lava \
    --lava_input_info input_info.txt \
    --lava_loci_file test.loci \
    --lava_ref_plink "reference.{bed,bim,fam}" \
    -profile singularity
```

### Causal Inference

**LCV Analysis**:
```bash
nextflow run main.nf \
    --project causal_inference \
    --run_causal_inference true \
    --causal_inference_method lcv \
    --lcv_sumstats1 exposure_gwas.txt \
    --lcv_sumstats2 outcome_gwas.txt \
    --lcv_ldscores ldscores.l2.ldscore.gz \
    -profile singularity
```

---

## Output Files

Output files are organized by analysis type in the specified output directory:

```
output/
├── my_project/
│   ├── association/
│   │   ├── regenie/
│   │   │   ├── *.regenie.gz          # Association results
│   │   │   └── *.log                  # Log files
│   │   └── ldak_kvik/
│   │       ├── kvik.step2.assoc       # GWAS summary statistics
│   │       └── kvik.step3.remls.all   # Gene-based results
│   │
│   ├── heritability/
│   │   ├── gcta/
│   │   │   └── *.hsq                  # Heritability estimates
│   │   └── ldak/
│   │       ├── *.reml                 # REML results
│   │       ├── *.he                   # HE regression results
│   │       └── *.hers                 # SumHer results
│   │
│   ├── genetic_correlation/
│   │   ├── ldak/
│   │   │   └── *.cors                 # Genetic correlations
│   │   └── lava/
│   │       ├── *.univ.lava            # Univariate results
│   │       └── *.bivar.lava           # Bivariate local rg
│   │
│   └── causal_inference/
│       └── lcv/
│           └── *.lcv.results          # GCP estimates
```

### Key Output Descriptions

**Heritability (*.hsq, *.reml)**:
- `V(G)`: Genetic variance
- `V(e)`: Environmental variance
- `h2`: Heritability estimate (V(G) / V(P))
- `SE`: Standard error

**Association (*.regenie, *.assoc)**:
- `CHR`, `POS`: Genomic position
- `BETA`: Effect size
- `SE`: Standard error
- `P`: P-value

**Genetic Correlation (*.cors)**:
- `rg`: Genetic correlation coefficient
- `SE`: Standard error
- `P`: P-value for rg ≠ 0

---

## Configuration

### Execution Profiles

Combine profiles as needed:

```bash
# Local development
nextflow run main.nf -profile development,singularity

# HPC with SLURM
nextflow run main.nf -profile slurm,singularity

# HPC with scratch space
nextflow run main.nf -profile slurm_with_scratch,singularity

# Quick testing
nextflow run main.nf -profile test,singularity
```

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--project` | Project name | Required |
| `--outdir` | Output directory | `output/${project}` |
| `--phenotypes_filename` | Phenotype file | Required |
| `--phenotypes_columns` | Phenotype column names | Required |
| `--phenotypes_binary_trait` | Binary trait flag | `false` |
| `--covariates_filename` | Covariate file | Optional |
| `--nparts_gcta` | GRM parallelization | `10` |

### Resource Configuration

Modify `conf/base.config` to adjust computational resources:

```groovy
process {
    withLabel: 'process_low' {
        cpus = 2
        memory = 4.GB
    }
    withLabel: 'process_medium' {
        cpus = 8
        memory = 32.GB
    }
    withLabel: 'process_high' {
        cpus = 16
        memory = 64.GB
    }
}
```

---

## Workflows

Detailed documentation for each workflow is available in the respective directories:

| Workflow | Documentation | Description |
|----------|---------------|-------------|
| REGENIE | [workflows/regenie/README.md](workflows/regenie/README.md) | Two-step GWAS for large biobanks |
| GCTA | [workflows/gcta/README.md](workflows/gcta/README.md) | GRM-based heritability and FastGWA |
| LDAK | [workflows/ldak/README.md](workflows/ldak/README.md) | LD-aware kinship, heritability, KVIK GWAS |
| BOLT-LMM | [workflows/bolt_lmm/README.md](workflows/bolt_lmm/README.md) | Fast mixed model analysis |
| LAVA | [workflows/lava/README.md](workflows/lava/README.md) | Local genetic correlation |
| LCV | [workflows/lcv/README.md](workflows/lcv/README.md) | Causal inference |

---

## Troubleshooting

### Common Issues

**1. Out of Memory**
```
Error: Process exceeded memory limit
```
**Solution**: Increase memory in profile or reduce `--nparts_gcta`.

**2. Container Not Found**
```
Error: Unable to find container image
```
**Solution**: Build container with `singularity build nf-gwas.sif nf-gwas.def`.

**3. Phenotype/Covariate Mismatch**
```
Error: Sample IDs do not match between genotype and phenotype files
```
**Solution**: Ensure FID and IID columns match across all input files.

**4. VCF Conversion Fails**
```
Error: VCF file has no variants after filtering
```
**Solution**: Check that VCF files are not empty and contain the expected samples.

### Getting Help

1. Check workflow-specific documentation (links above)
2. Review log files in the `work/` directory
3. Open an issue on [GitHub](https://github.com/genepi/nf-gwas/issues)

---

## Testing

Run the test suite:

```bash
# Run all tests
nf-test test

# Run specific workflow test
nf-test test tests/modules/local/regenie_step1.nf.test

# Run main workflow test
nf-test test tests/main.nf.test
```

---

## Citation

If you use nf-gwas in your research, please cite:

```
[Citation information to be added]
```

Also cite the underlying tools used in your analysis:
- **REGENIE**: Mbatchou et al. (2021) Nature Genetics
- **GCTA**: Yang et al. (2011) American Journal of Human Genetics
- **LDAK**: Speed et al. (2012) American Journal of Human Genetics
- **BOLT-LMM**: Loh et al. (2015) Nature Genetics
- **LAVA**: Werme et al. (2022) Nature Genetics
- **LCV**: O'Connor & Price (2018) Nature Genetics

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please see our contributing guidelines and submit pull requests to the main repository.
