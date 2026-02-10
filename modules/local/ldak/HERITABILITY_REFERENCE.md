# LDAK Heritability Process Reference

[LDAK Modules](CLAUDE.md) > **Heritability Estimation Processes**

Detailed reference for LDAK heritability estimation processes.

---

## Individual-Level Data Methods

### LDAK_REML

**File**: `ldak_reml.nf`

**Purpose**: Run LDAK REML heritability estimation

**Inputs**:
- Kinship matrix
- `tuple val(filtered_list_name), path(keep), path(lose), path(maxrel)`: Filtering lists
- `path phenotype_file`: Phenotype data
- `path quant_covariates_file`: Quantitative covariates (optional)
- `path cat_covariates_file`: Categorical covariates (optional)

**Outputs**:
- Multiple output files (see below)
- `path "reml_*.reml"`: Main REML results (emitted)

**Script Logic**:
```bash
ldak6 \
    --reml reml_${combined_grm_name} \
    --pheno ${phenotype_file} \
    ${keep_param} \
    --grm ${combined_grm_name} \
    ${quant_covar_param} \
    ${cat_covar_param} \
    ${prevalence_param} \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--reml`: REML estimation mode
- `--keep`: Use only unrelated individuals
- `--covar`: Quantitative covariates
- `--factors`: Categorical covariates
- `--prevalence`: Optional for binary traits (enabled via `params.ldak_reml_prevalence`)

**Output Files**:
```
reml_*.reml          # Main REML results (Her_ALL, Her_SE, etc.)
reml_*.coeff         # Coefficient estimates
reml_*.combined      # Combined variance components
reml_*.progress      # Iteration progress
reml_*.share         # Shared variance
reml_*.vars          # Variance components
reml_*.indi.blp      # Individual BLUPs
reml_*.indi.res      # Individual residuals
```

**Methodology**: Consult **LDAK skill** for detailed REML methodology.

**publishDir**: `${params.pubDir}/ldak/reml`

---

### LDAK_HE

**File**: `ldak_he.nf`

**Purpose**: Run Haseman-Elston regression for heritability

**Inputs**: Similar to LDAK_REML

**Outputs**:
- `path "he_*.he"`: HE regression results

**Script Logic**:
```bash
ldak6 \
    --he he_${grm_name} \
    --pheno ${phenotype_file} \
    --grm ${grm_name} \
    ${covar_params} \
    --max-threads ${task.cpus}
```

**Key Features**:
- **10-100x faster than REML**
- Slight accuracy trade-off (typically <5% difference)
- Ideal for large datasets (N > 100k)
- Useful for QC and genotype error estimation

**Use Case**: Fast heritability screening or when computational resources are limited.

**Methodology**: Consult **LDAK skill** for detailed HE regression methodology (doc 41).

**publishDir**: `${params.pubDir}/ldak/he`

---

### LDAK_PCGC

**File**: `ldak_pcgc.nf`

**Purpose**: Run PCGC regression for binary trait heritability on liability scale

**Inputs**:
- `tuple val(combined_grm_name), path(grm_bin), path(grm_id), path(grm_details), path(grm_adjust)`: Kinship matrix
- `tuple val(filtered_list_name), path(keep), path(lose), path(maxrel)`: Filtering lists
- `path phenotype_file`: Binary phenotype data (0/1 or 1/2 encoding)
- `path quant_covariates_file`: Quantitative covariates (optional)
- `path cat_covariates_file`: Categorical covariates (optional)

**Outputs**:
- `path "pcgc_*.pcgc"`: Main PCGC results (liability-scale h²)
- `path "pcgc_*.progress"`: Iteration progress (optional)
- `path "pcgc_*.*"`: All PCGC output files

**Script Logic**:
```bash
ldak6 --pcgc pcgc_${combined_grm_name} \
      --pheno ${phenotype_file} \
      ${keep_param} \
      --grm ${combined_grm_name} \
      ${quant_covar_param} \
      ${cat_covar_param} \
      ${prevalence_param} \
      --max-threads ${task.cpus}
```

**Key Parameters**:
- `--pcgc`: PCGC regression mode (binary traits)
- `--prevalence ${params.ldak_pcgc_prevalence}`: **Disease prevalence (REQUIRED)**
- `--keep`: Use only unrelated individuals
- `--covar`: Quantitative covariates
- `--factors`: Categorical covariates

**Critical Notes**:
- **Prevalence parameter is mandatory** for meaningful liability-scale estimates
- Converts observed-scale heritability to liability-scale
- Accounts for ascertainment bias in case-control designs
- Only use for binary traits (case-control studies)

**Use Case**: Critical for case-control studies where trait prevalence differs from population prevalence.

**Methodology**: Consult **LDAK skill** for detailed PCGC methodology (doc 69-70).

**publishDir**: `${params.pubDir}/ldak/pcgc`

**Example Output Interpretation**:
```
Her_Liab  0.45  # Liability-scale heritability
SE        0.08  # Standard error
Prevalence 0.20 # Disease prevalence used
```

---

## Summary Statistics Methods

### LDAK_SUMHER

**File**: `ldak_sumher.nf`

**Purpose**: Estimate heritability from summary statistics

**Inputs**:
- `tuple val(trait_name), path(summary_stats)`: GWAS summary statistics
- `path tagfile`: Pre-computed tagging file

**Outputs**:
- `path "${trait_name}.hers"`: Heritability estimates
- `path "${trait_name}.enrich"`: Enrichment statistics (optional)
- Other optional outputs (.load, .progress)

**Script Logic**:
```bash
ldak6 \
    --sum-hers ${trait_name} \
    --summary ${summary_stats} \
    --tagfile ${tagfile} \
    ${check_sums} \
    ${prevalence} \
    ${cutoff} \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--sum-hers`: Summary statistics heritability
- `--tagfile`: Pre-computed tagging file (download from LDAK website)
- `--check-sums NO`: Skip sum check (optional)
- `--prevalence`: Disease prevalence for binary traits
- `--cutoff`: MAF cutoff

**Required Input Format**:
```
Predictor  A1  A2  n       Z
rs12345    A   G   100000  2.45
rs67890    C   T   100000  -1.23
```

**Where**:
- `Predictor`: SNP ID
- `A1`: Effect allele
- `A2`: Reference allele
- `n`: Sample size
- `Z`: Z-score (or provide beta and SE)

**Methodology**: Consult **LDAK skill** for detailed SumHer methodology (doc 71-80).

**publishDir**: `${params.pubDir}/ldak/sumher`

---

### LDAK_SUMCORS

**File**: `ldak_sumcors.nf`

**Purpose**: Estimate genetic correlation between traits from summary statistics

**Inputs**:
- `tuple val(trait1_name), path(stats1), val(trait2_name), path(stats2)`: Summary statistics pairs
- `path tagfile`: Pre-computed tagging file

**Outputs**:
- `path "${trait1_name}_${trait2_name}.cors"`: Correlation results

**Script Logic**:
```bash
ldak6 \
    --sum-cors ${trait1_name}_${trait2_name} \
    --summary ${stats1} \
    --summary2 ${stats2} \
    --tagfile ${tagfile} \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--sum-cors`: Genetic correlation estimation
- `--summary`: First trait summary statistics
- `--summary2`: Second trait summary statistics

**Output Interpretation**:
```
rg     0.65   # Genetic correlation (-1 to +1)
SE     0.12   # Standard error
P      5e-8   # P-value for rg != 0
```

**Use Case**: Identify shared genetic architecture between traits without requiring individual-level data.

**Methodology**: Consult **LDAK skill** for SumCors details.

**publishDir**: `${params.pubDir}/ldak/sumcors`

---

## Method Comparison

| Method | Input Required | Speed | Accuracy | Best For |
|--------|---------------|-------|----------|----------|
| **REML** | Individual-level data | Slow | Highest | Gold standard, small-medium datasets (N < 100k) |
| **HE Regression** | Individual-level data | **Fast (10-100x)** | High (±5%) | Large datasets (N > 100k), QC, screening |
| **PCGC** | Individual-level data (binary) | Medium | High | Case-control studies, liability-scale h² |
| **SumHer** | Summary statistics | Fast | High (comparable to REML) | No individual data available |
| **SumCors** | Summary statistics (2 traits) | Fast | High | Genetic correlation without individual data |

---

## Expected Output Ranges

**Heritability (h²)**:
- Range: 0 to 1 (slightly negative values possible due to sampling variance)
- Typical human complex traits: 0.1 to 0.8
- Height: ~0.5-0.8
- BMI: ~0.3-0.5
- Psychiatric traits: ~0.2-0.4

**Genetic Correlation (rg)**:
- Range: -1 to +1
- rg > 0: Shared genetic architecture (same direction)
- rg < 0: Opposite genetic effects
- rg ≈ 0: Independent traits

**Standard Errors**:
- Inversely proportional to sample size
- Typical SE for N=10k: ~0.1
- Typical SE for N=100k: ~0.03

---

## Related Documentation

- [LDAK Modules Overview](CLAUDE.md)
- [Kinship Process Reference](KINSHIP_REFERENCE.md)
- [QC Process Reference](QC_REFERENCE.md)
- [LDAK Workflows](../../../workflows/ldak/CLAUDE.md)
