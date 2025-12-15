# BOLT-LMM Workflows

[Root Directory](../../CLAUDE.md) > [workflows](../CLAUDE.md) > **bolt_lmm**

## Change Log (Changelog)

### 2025-12-13 09:41:58
- Initial documentation creation
- Documented BOLT-LMM REML heritability estimation workflow

---

## Module Responsibilities

BOLT-LMM (Bayesian Open-source Linkage-based Test for Linear Mixed Models) workflows implement fast mixed model association testing and heritability estimation. Currently implemented:

1. **BOLT_LMM_REML**: REML-based variance component estimation

**Key Features**:
- Fast computation via randomized algorithms
- Calibrated test statistics for population structure
- Support for quantitative and binary traits
- Handles multiple phenotypes simultaneously
- Efficient for biobank-scale datasets (100k+ samples)

**Note**: This is a minimal implementation focusing on REML. Full association testing workflows are not yet implemented but can be added following the same pattern.

---

## Entry and Startup

### Primary Workflow

**BOLT_LMM_REML** (`bolt_lmm_reml.nf`)
- Runs BOLT-LMM REML analysis for heritability estimation
- Requires PLINK1 format files (bed/bim/fam)
- Supports multiple chromosomes concatenated
- Outputs variance component estimates and log files

### Invocation Pattern
```groovy
include { BOLT_LMM_REML } from './workflows/bolt_lmm/bolt_lmm_reml'

BOLT_LMM_REML(
    imputed_plink_ch,
    phenotypes_file,
    covariates_file
)
```

---

## External Interfaces

### Input Channels

**BOLT_LMM_REML**:
- `imputed_plink_ch`: PLINK files `[chr_num, filename, bed, bim, fam, range]`
  - All chromosomes are collected and passed to BOLT
  - FAM file is taken from first chromosome (assumed identical across all)
- `phenotypes_file`: Path to phenotype file
- `covariates_file`: Path to covariate file

### Output Channels

**BOLT_LMM_REML**:
- `log_file`: BOLT-LMM log file containing REML results
  - Format: `<phenotype_basename>.bolt.reml.log`
  - Contains variance component estimates, heritability, and convergence info

---

## Key Dependencies and Configuration

### Process Dependencies

**BOLT_LMM_REML uses**:
- `modules/local/bolt_lmm/run_reml.nf`: Execute BOLT-LMM REML
- Requires PLINK1 format files (not PLINK2)

### Configuration Parameters

**Required Parameters**:
- `params.phenotypes_filename`: Phenotype file path
- `params.phenotypes_columns`: Phenotype column names (comma-separated)
- `params.covariates_filename`: Covariate file path
- `params.covariates_columns`: All covariate column names
- `params.covariates_cat_columns`: Categorical covariate subset

**BOLT-LMM Specific**:
- `task.cpus`: Number of threads (controlled by process resources)
- Output is written to stdout/stderr and captured in log file

**File Format Requirements**:
- Phenotype file: Space/tab-delimited with FID, IID, phenotype columns
- Covariate file: Space/tab-delimited with FID, IID, covariate columns
- PLINK files: Standard bed/bim/fam format

### Tool Requirements
- **BOLT-LMM v2.3+**: Mixed model estimation
- **PLINK1 format data**: bed/bim/fam files

---

## Data Models

### Input File Structures

**PLINK1 Files**:
```
chr01.bed, chr01.bim, chr01.fam
chr02.bed, chr02.bim, chr02.fam
...
```
- All .bed files are passed via `--bed` flags
- All .bim files are passed via `--bim` flags
- Single .fam file is used (from first chromosome)

**Phenotype File**:
```
FID    IID    Pheno1    Pheno2
1001   1001   1.23      0
1002   1002   -0.45     1
```

**Covariate File**:
```
FID    IID    Age    Sex    PC1      PC2
1001   1001   45     1      0.01     -0.02
1002   1002   52     2      0.03     0.01
```

### Output Structure

**Log File Format**:
```
<phenotype_basename>.bolt.reml.log

Contains:
- Command line used
- Data summary (N samples, N SNPs)
- Variance component estimates:
  * σ²_g (genetic variance)
  * σ²_e (environmental variance)
  * h² = σ²_g / (σ²_g + σ²_e)
- Log-likelihood
- Convergence information
```

---

## Workflow Logic Details

### BOLT_LMM_REML Pipeline
```
1. Collect PLINK files from channel
   - bed_plink_files: List of all .bed files
   - bim_plink_files: List of all .bim files
   - fam_plink_file: Single .fam file (from first chromosome)

2. Parse parameters
   - phenoCols: Split phenotypes_columns into individual --phenoCol flags
   - covarCols: Split categorical covariates into --covarCol flags
   - qcovarCols: Split quantitative covariates into --qCovarCol flags

3. Build BOLT command
   --reml
   --bed chr01.bed --bim chr01.bim
   --bed chr02.bed --bim chr02.bim
   ...
   --fam combined.fam
   --phenoFile phenotypes.txt
   --phenoCol=Pheno1 --phenoCol=Pheno2
   --covarFile covariates.txt
   --covarCol=Sex --qCovarCol=Age --qCovarCol=PC1 ...
   --numThreads <cpus>

4. Execute BOLT and capture log
   &> <phenotype_basename>.bolt.reml.log
```

### Parameter Construction Details
```groovy
// Build --bed --bim pairs
def bedBimFlags = [bed_plink_files, bim_plink_files]
     .transpose()
     .collect { bed, bim -> "--bed ${bed} --bim ${bim}" }
     .join(' ')

// Build --phenoCol flags
def phenoCols = params.phenotypes_columns
    .split(',')
    .collect { "--phenoCol=${it}" }
    .join(' ')

// Build --covarCol and --qCovarCol flags
def allCovars = params.covariates_columns.split(',')
def catCovars = params.covariates_cat_columns.split(',')
def covarCols = catCovars
    .collect { "--covarCol=${it}" }
    .join(' ')
def qcovarCols = allCovars
    .minus(catCovars)
    .collect { "--qCovarCol=${it}" }
    .join(' ')
```

---

## Testing and Quality

### Module Tests
No dedicated BOLT-LMM workflow tests currently exist. Testing relies on:
- Manual execution with test data
- Integration testing in main pipeline

### Expected Behavior
- REML should converge within reasonable iterations
- Heritability estimates should be between 0 and 1
- Log file should contain clear variance component estimates
- Execution time should be significantly faster than GCTA for large N

---

## Usage Examples

### Basic REML Heritability
```groovy
// Assuming imputed_plink_ch contains PLINK1 files
BOLT_LMM_REML(
    imputed_plink_ch,
    file("phenotypes.txt"),
    file("covariates.txt")
)

// Output: phenotypes.bolt.reml.log
```

### Multiple Phenotypes
```groovy
// params.phenotypes_columns = "Height,BMI,Weight"
BOLT_LMM_REML(
    imputed_plink_ch,
    file("phenotypes.txt"),
    file("covariates.txt")
)

// BOLT will estimate h² for all three phenotypes
```

### With Categorical and Quantitative Covariates
```groovy
// params.covariates_columns = "Age,Sex,PC1,PC2,PC3"
// params.covariates_cat_columns = "Sex"
// → Age, PC1-3 become qCovarCol
// → Sex becomes covarCol

BOLT_LMM_REML(
    imputed_plink_ch,
    file("phenotypes.txt"),
    file("covariates.txt")
)
```

---

## Frequently Asked Questions (FAQ)

**Q: Why does BOLT-LMM require PLINK1 format instead of PLINK2?**
A: BOLT-LMM v2.3 was designed for PLINK1 format. The workflow converts VCF to PLINK1 via `imputed_to_plink.nf`.

**Q: Can I use BOLT-LMM for association testing?**
A: Yes, but the workflow currently only implements REML. Association testing workflows can be added following the same pattern with `--lmm` or `--lmmInfOnly` flags.

**Q: How does BOLT-LMM handle binary traits?**
A: BOLT-LMM automatically detects binary traits (0/1 or 1/2 coding) and applies appropriate liability-scale transformation.

**Q: What's the difference between BOLT-LMM REML and GCTA REML?**
A: BOLT-LMM uses randomized algorithms for O(N) complexity vs. GCTA's O(N²). BOLT is faster for large N but may be less precise for small N.

**Q: Why am I getting "Not enough memory" errors?**
A: BOLT-LMM loads all SNPs into memory. Ensure adequate RAM (recommend 2-4 GB per 100k SNPs).

**Q: How do I extract heritability from the log file?**
A: Search for lines containing "h2" or "heritability" in the log file. Values are typically reported as:
```
h2 = 0.45 (SE = 0.03)
```

**Q: Can I run BOLT-LMM with related individuals?**
A: BOLT-LMM can handle moderate relatedness but is not optimized for closely related samples. Consider removing relatives (kinship > 0.05) for best results.

**Q: What is the minimum sample size for BOLT-LMM?**
A: BOLT-LMM works best with N > 5,000. For smaller samples, GCTA REML may be more appropriate.

---

## Workflow Files

- `bolt_lmm_reml.nf`: BOLT-LMM REML workflow (48 lines)

---

## Related Documentation

- [BOLT-LMM Modules](../../modules/local/bolt_lmm/CLAUDE.md)
- [Root Documentation](../../CLAUDE.md)
- [Workflows Overview](../CLAUDE.md)
- [BOLT-LMM Documentation](https://alkesgroup.broadinstitute.org/BOLT-LMM/)

---

## Future Enhancements

Potential additions to this workflow module:

1. **Association Testing Workflow**:
   - `bolt_lmm_assoc.nf`: Full mixed model association
   - Support for `--lmm`, `--lmmInfOnly`, `--lmmForceNonInf`

2. **Imputation Quality Filtering**:
   - `--minMAF`, `--minINFO` parameters
   - QC filtering integration

3. **Dosage File Support**:
   - Direct VCF/BGEN input via `--bgenFile`
   - Avoid PLINK1 conversion step

4. **Batch Processing**:
   - Chromosome-parallel association testing
   - Result merging and meta-analysis

5. **Advanced Options**:
   - PCA calculation (`--numPCAOutliers`)
   - Model SNPs (`--modelSnps`)
   - Leave-one-chromosome-out (LOCO) predictions
