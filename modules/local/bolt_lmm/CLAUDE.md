# BOLT-LMM Modules

[Root Directory](../../../CLAUDE.md) > [modules/local](../CLAUDE.md) > **bolt_lmm**

## Change Log (Changelog)

### 2025-12-13 09:41:58
- Initial documentation creation
- Documented BOLT-LMM REML process module

---

## Module Responsibilities

BOLT-LMM (Bayesian Open-source Linkage-based Test for Linear Mixed Models) process modules implement fast mixed model methods for heritability estimation and association testing. Currently implemented:

**REML Estimation**:
- Variance component estimation for quantitative and binary traits
- Fast computation via randomized matrix algorithms
- Support for multiple phenotypes and covariates

**Note**: This is a minimal implementation. Full association testing modules can be added following the same pattern.

---

## Module Index

| Module | Purpose | Input | Output | Resource |
|--------|---------|-------|--------|----------|
| `run_reml.nf` | BOLT-LMM REML heritability | PLINK1 files, phenotypes, covariates | Log file with h² estimates | Default |

---

## Process Details

### RUN_BOLT_REML

**Purpose**: Execute BOLT-LMM REML analysis for variance component estimation

**Inputs**:
- `path bed_plink_files`: List of all .bed files (all chromosomes)
- `path bim_plink_files`: List of all .bim files (all chromosomes)
- `path fam_plink_file`: Single .fam file (from first chromosome)
- `path phenotypes_file`: Phenotype file
- `path covariates_file`: Covariate file

**Outputs**:
- `path "${phenotypes_file.baseName}.bolt.reml.log"`: Log file containing REML results

**Script Construction**:

The script builds a complex BOLT command by:

1. **Creating bed/bim pairs**:
```groovy
def bedBimFlags = [bed_plink_files, bim_plink_files]
     .transpose()                        // Zip bed and bim lists
     .collect { bed, bim ->              // Create flag pairs
       "--bed ${bed} --bim ${bim}"
     }
     .join(' ')                          // Concatenate all pairs
// Result: "--bed chr01.bed --bim chr01.bim --bed chr02.bed --bim chr02.bim ..."
```

2. **Creating phenotype columns**:
```groovy
def phenoCols = params.phenotypes_columns
                   .split(',')                    // Split comma-separated list
                   .collect { "--phenoCol=${it}" } // Create flag per column
                   .join(' ')
// Result: "--phenoCol=Height --phenoCol=BMI --phenoCol=Weight"
```

3. **Separating categorical and quantitative covariates**:
```groovy
def allCovars  = params.covariates_columns.split(',')
def catCovars  = params.covariates_cat_columns.split(',')

def covarCols  = catCovars
                   .collect { "--covarCol=${it}" }
                   .join(' ')
// Result: "--covarCol=Sex --covarCol=Batch"

def qcovarCols = allCovars
                   .minus(catCovars)                 // Remove categorical from all
                   .collect { "--qCovarCol=${it}" }
                   .join(' ')
// Result: "--qCovarCol=Age --qCovarCol=PC1 --qCovarCol=PC2 ..."
```

**Final BOLT Command**:
```bash
bolt \
  --reml \
  --bed chr01.bed --bim chr01.bim \
  --bed chr02.bed --bim chr02.bim \
  ... (all chromosomes) \
  --fam combined.fam \
  --phenoFile phenotypes.txt \
  --phenoCol=Pheno1 --phenoCol=Pheno2 \
  --covarFile covariates.txt \
  --covarCol=Sex --covarCol=Batch \
  --qCovarCol=Age --qCovarCol=PC1 --qCovarCol=PC2 \
  --numThreads ${task.cpus} \
  &> ${outPrefix}.bolt.reml.log
```

**Key Parameters**:
- `--reml`: REML mode (variance component estimation only)
- `--bed` / `--bim`: PLINK1 genotype files (multiple allowed)
- `--fam`: Sample information (single file for all chromosomes)
- `--phenoFile`: Phenotype file path
- `--phenoCol`: Individual phenotype columns
- `--covarFile`: Covariate file path
- `--covarCol`: Categorical covariate columns
- `--qCovarCol`: Quantitative covariate columns
- `--numThreads`: CPU parallelization
- `&>`: Redirect stdout and stderr to log file

**publishDir**: `${params.pubDir}/bolt_reml`

---

## Input File Format Requirements

### PLINK1 Files
```
chr01.bed, chr01.bim, chr01.fam
chr02.bed, chr02.bim, chr02.fam
...
```
- **bed**: Binary genotype data
- **bim**: Variant information (6 columns: chr, rsID, cM, pos, A1, A2)
- **fam**: Sample information (6 columns: FID, IID, father, mother, sex, phenotype)

**Important**: BOLT-LMM requires PLINK1 format, not PLINK2.

### Phenotype File
Space or tab-delimited text file with header:
```
FID    IID    Pheno1    Pheno2    Pheno3
1001   1001   1.234     0.567     1
1002   1002   -0.456    1.234     0
1003   1003   NA        0.890     1
```
- **FID**: Family ID
- **IID**: Individual ID
- **Pheno columns**: Phenotype values (NA for missing)

### Covariate File
Space or tab-delimited text file with header:
```
FID    IID    Age    Sex    PC1      PC2      PC3
1001   1001   45     1      0.012    -0.023   0.001
1002   1002   52     2      0.034    0.012    -0.015
1003   1003   38     1      -0.001   0.045    0.023
```
- **FID/IID**: Sample identifiers
- **Covariate columns**: Covariate values

**Categorical vs. Quantitative**:
- Categorical (e.g., Sex, Batch): Use `--covarCol`
- Quantitative (e.g., Age, PCs): Use `--qCovarCol`
- Pipeline automatically separates based on `params.covariates_cat_columns`

---

## Output Format

### Log File Structure

The log file (`*.bolt.reml.log`) contains:

1. **Command invocation**: Exact BOLT command used
2. **Data summary**:
   ```
   Loaded N individuals from PLINK .fam file
   Loaded M SNPs from PLINK .bim files
   ```
3. **Phenotype summary** (per phenotype):
   ```
   Analyzing phenotype: Height
   Non-missing individuals: 95,432
   Mean: 170.5 cm
   SD: 8.2 cm
   ```
4. **REML estimates**:
   ```
   Variance component estimates:
   σ²_g (genetic variance): 42.3 (SE = 2.1)
   σ²_e (environmental variance): 25.1 (SE = 1.5)
   h² (heritability): 0.628 (SE = 0.035)
   Log-likelihood: -123456.78
   ```
5. **Convergence information**:
   ```
   REML iterations: 12
   Converged: YES
   ```

**Extracting h² from log**:
```bash
grep "h²" *.bolt.reml.log
# Or use more robust parsing:
awk '/heritability/ {print $NF}' *.bolt.reml.log
```

---

## Data Flow

### BOLT_LMM_REML Workflow Data Flow
```
imputed_plink_ch (multiple chromosomes)
    ↓
    ├─ Extract .bed files → bed_plink_files (list)
    ├─ Extract .bim files → bim_plink_files (list)
    └─ Extract .fam file → fam_plink_file (first only)
    ↓
RUN_BOLT_REML
    ↓
<phenotype>.bolt.reml.log
```

### Channel Transformation
```groovy
// Input channel: tuple(chr_num, filename, bed, bim, fam, range)
imputed_plink_ch

// Extract bed files
bed_plink_files = imputed_plink_ch
    .map { _chr_num, _filename, bed, _bim, _fam, _range -> bed }
    .collect()
// Result: [chr01.bed, chr02.bed, chr03.bed, ...]

// Extract bim files
bim_plink_files = imputed_plink_ch
    .map { _chr_num, _filename, _bed, bim, _fam, _range -> bim }
    .collect()
// Result: [chr01.bim, chr02.bim, chr03.bim, ...]

// Extract single fam file
fam_plink_file = imputed_plink_ch
    .map { _chr_num, _filename, _bed, _bim, fam, _range -> fam }
    .first()
// Result: chr01.fam (assumed identical across all chromosomes)
```

---

## Algorithm Details

### BOLT-LMM REML Method

**Computational Complexity**:
- Standard mixed model: O(N³) where N = sample size
- BOLT-LMM REML: O(N²) via randomized algorithms

**Algorithm**:
1. **Monte Carlo averaging**: Approximate log-likelihood using randomized traces
2. **Conjugate gradient**: Solve linear systems iteratively
3. **Average information**: Efficient Fisher information estimation
4. **Convergence**: Iterate until log-likelihood change < threshold

**Advantages**:
- Fast for large N (>50k samples)
- Calibrated test statistics
- Handles population structure

**Limitations**:
- Less precise than exact methods for small N (<5k)
- Requires sufficient SNP density

---

## Testing and Quality

### Expected Behavior
- REML should converge within 10-20 iterations
- h² should be between 0 and 1
- Standard errors should be reasonable (typically 0.02-0.10 for well-powered studies)
- Log file should report "Converged: YES"

### Common Issues

**1. Non-convergence**:
```
REML failed to converge
```
**Solutions**:
- Check phenotype distribution (extreme outliers?)
- Ensure sufficient sample size (N > 5000)
- Verify covariate files are correct

**2. Negative heritability**:
```
h² = -0.05 (SE = 0.12)
```
**Interpretation**: Consistent with h² = 0 given SE. Constrain to 0.

**3. Memory errors**:
```
Error: Out of memory
```
**Solutions**:
- Reduce SNP count (LD prune to ~100k SNPs)
- Increase memory allocation
- Filter to MAF > 0.01

---

## Usage Examples

### Basic REML
```groovy
RUN_BOLT_REML(
    [file("chr01.bed"), file("chr02.bed")],
    [file("chr01.bim"), file("chr02.bim")],
    file("chr01.fam"),
    file("phenotypes.txt"),
    file("covariates.txt")
)

// Output: phenotypes.bolt.reml.log
```

### Multiple Phenotypes
```groovy
// params.phenotypes_columns = "Height,BMI,Weight"
RUN_BOLT_REML(...)

// Output log contains h² for all three phenotypes
```

### With Categorical and Quantitative Covariates
```groovy
// params.covariates_columns = "Age,Sex,PC1,PC2,PC3,Batch"
// params.covariates_cat_columns = "Sex,Batch"
// → Age, PC1-3 become qCovarCol
// → Sex, Batch become covarCol

RUN_BOLT_REML(...)
```

---

## Frequently Asked Questions (FAQ)

**Q: Why does BOLT-LMM need PLINK1 instead of PLINK2?**
A: BOLT-LMM v2.3 was designed for PLINK1 format. Future versions may support PLINK2.

**Q: Can I use VCF files directly?**
A: No, convert to PLINK1 first using `imputed_to_plink.nf` module.

**Q: How many SNPs should I use for REML?**
A: 100k-500k well-imputed SNPs is typical. More SNPs don't necessarily improve h² estimates.

**Q: What's the minimum sample size?**
A: BOLT-LMM works best with N > 5000. For smaller N, consider GCTA.

**Q: How long does REML take?**
A: ~10-30 minutes for 100k samples, 500k SNPs on 16 CPUs.

**Q: Can I run association testing with this module?**
A: No, this module only runs REML. Association testing requires different BOLT-LMM flags (`--lmm` or `--lmmInfOnly`).

**Q: What if chromosomes have different .fam files?**
A: This should not happen. PLINK .fam files should be identical across chromosomes. The workflow uses .first() to extract one.

**Q: How do I interpret the log file?**
A: Look for "h² (heritability)" and "SE" lines. Example:
```
h² = 0.628 (SE = 0.035)
```
This means estimated heritability is 62.8% ± 3.5%.

---

## Process File

- `run_reml.nf`: BOLT-LMM REML process (57 lines)

---

## Related Documentation

- [BOLT-LMM Workflow](../../../workflows/bolt_lmm/CLAUDE.md)
- [Modules Overview](../CLAUDE.md)
- [Root Documentation](../../../CLAUDE.md)
- [BOLT-LMM Official Docs](https://alkesgroup.broadinstitute.org/BOLT-LMM/)

---

## Future Enhancements

Potential additions to this module directory:

1. **Association Testing Module**:
   - `run_association.nf`: Full mixed model association
   - Support for `--lmm`, `--lmmInfOnly`, `--lmmForceNonInf` flags
   - Per-chromosome parallelization

2. **Imputation Quality Filtering**:
   - `run_reml_filtered.nf`: With MAF and INFO filtering
   - `--minMAF`, `--minINFO` parameters

3. **PCA Module**:
   - `calculate_pcs.nf`: PCA calculation
   - `--numPCAOutliers` for outlier detection

4. **Model SNPs Module**:
   - `run_reml_model_snps.nf`: Condition on specific SNPs
   - `--modelSnps` parameter

5. **LOCO Predictions**:
   - `generate_loco.nf`: Leave-one-chromosome-out predictions
   - For downstream meta-analysis or conditional analysis

Each module would follow the same pattern as `run_reml.nf` with appropriate parameter modifications.
