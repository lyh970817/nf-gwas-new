# LDAK Quality Control Process Reference

[LDAK Modules](CLAUDE.md) > **Quality Control Processes**

Detailed reference for LDAK quality control and diagnostic processes.

---

## Quality Control Processes

### CALC_INFLATION

**File**: `calc_inflation.nf`

**Purpose**: Calculate inflation factor comparing full vs. quarter heritability

**Inputs**:
- `path ldak_reml_file`: Full-data REML results
- `path quarter_reml_files`: Quarter-specific REML results

**Outputs**:
- `path "inflation_results.txt"`: Inflation statistics

**Script Logic**:
```bash
calc_inflation.R ${ldak_reml_file} ${quarter_reml_files.join(' ')}
```

**R Script Logic**:
1. Parse h² from full REML file
2. Parse h² from each quarter REML file
3. Calculate inflation = h²_full / mean(h²_quarters)
4. Output: phenotype, h2_full, h2_quarter_mean, inflation_factor

**Methodology**:
The **chromosome quartering** method tests for inflation by:
1. Running REML on full genome → h²_full
2. Splitting genome into 4 quarters (chromosomes 1-5, 6-10, 11-15, 16-22)
3. Running REML on each quarter → h²_quarter1, h²_quarter2, h²_quarter3, h²_quarter4
4. Comparing: inflation = h²_full / mean(h²_quarters)

**Expected inflation = 4.0** (because each quarter has ~1/4 of genome)

**Interpretation**:
- **inflation ≈ 4.0**: No inflation (ideal)
- **inflation > 4.2**: Potential issues:
  - Population structure not fully captured
  - Cryptic relatedness
  - Residual confounding
  - Assortative mating
- **inflation < 3.8**: Possible over-correction:
  - Too many principal components
  - Over-filtering of related individuals
  - Model misspecification

**publishDir**: `${params.pubDir}/ldak/inflation`

**Example Output**:
```
phenotype    h2_full  h2_q1   h2_q2   h2_q3   h2_q4   h2_quarter_mean  inflation
height       0.60     0.14    0.16    0.15    0.15    0.150            4.00
BMI          0.48     0.13    0.11    0.12    0.13    0.123            3.90
case_control 0.35     0.11    0.10    0.08    0.09    0.095            3.68
```

**Recommendations**:
- If inflation > 4.2: Add more covariates (PCs, age, sex, batch)
- If inflation < 3.8: Remove covariates or relax relatedness filtering
- Rerun REML with adjusted parameters

---

### CALC_GENOTYPE_ERROR

**File**: `calc_genotype_error.nf` or `calc_genotype_error_t2.nf`

**Purpose**: Estimate genotype error rates using batch information

**Inputs**:
- PLINK files
- `path phenotype_file`
- `path covariates_file`
- `tuple val(batch_prefix), val(batch_number), val(batch_list)`: Batch identifiers

**Outputs**:
- `path "genotype_error.he"`: Error estimates

**Script Logic**:
```bash
# For each batch:
ldak6 \
    --he genotype_error_batch${i} \
    --pheno ${phenotype_file} \
    --grm batch${i}_grm \
    --max-threads ${task.cpus}

# Aggregate results
aggregate_genotype_error.R batch_results > genotype_error.he
```

**Methodology**:
Uses **batch-based kinship** to detect genotype errors:
1. Samples are genotyped in batches (plates, sequencing runs)
2. Calculate kinship within each batch
3. Run HE regression on batch-specific kinships
4. High h² from batch kinships indicates systematic errors within that batch
5. Compare batch h² to genome-wide h² to quantify error rate

**Interpretation**:
- **Error rate < 0.5%**: High-quality genotyping
- **Error rate 0.5-1%**: Acceptable quality
- **Error rate 1-2%**: Moderate quality, consider QC filters
- **Error rate > 2%**: Poor quality, investigate batch effects

**Common Causes of High Error Rates**:
- Plate/batch effects
- DNA degradation
- Contamination
- Genotyping platform differences
- Poor call rate variants

**Recommended Actions**:
1. Identify problematic batches
2. Exclude low-quality samples (batch-specific)
3. Apply stricter MAF/call rate filters
4. Consider batch as covariate in analysis
5. Regenotype problematic samples if possible

**Use Case**: Detect systematic genotyping errors or batch effects before running association analysis.

**publishDir**: `${params.pubDir}/ldak/genotype_error`

**Example Output**:
```
batch       h2_batch  h2_genome  error_rate  num_samples
batch1      0.02      0.50       0.4%        500
batch2      0.08      0.50       1.6%        500  # Problematic
batch3      0.01      0.50       0.2%        500
batch4      0.03      0.50       0.6%        500
```

---

## Quality Control Workflow

Typical QC pipeline order:

1. **Relatedness Filtering** (`FILTER_RELATEDNESS`)
   - Remove close relatives (kinship > 0.05)
   - Prevents bias in heritability estimates

2. **Initial REML** (`LDAK_REML`)
   - Estimate heritability on full genome
   - Baseline h² estimate

3. **Chromosome Quartering** (`LDAK_QC` workflow)
   - Split genome into 4 quarters
   - Run REML on each quarter
   - Check for inflation

4. **Inflation Testing** (`CALC_INFLATION`)
   - Calculate inflation factor
   - Diagnose population structure issues

5. **Genotype Error Estimation** (`CALC_GENOTYPE_ERROR`) (Optional)
   - Detect batch effects
   - Quantify genotyping quality

6. **Adjustment** (if needed)
   - Add covariates
   - Adjust filtering thresholds
   - Rerun REML

7. **Final Analysis**
   - Run production heritability analysis
   - Or proceed to association testing

---

## QC Metrics Summary

| Metric | Good | Acceptable | Poor | Action if Poor |
|--------|------|------------|------|----------------|
| **Inflation Factor** | 3.9-4.1 | 3.8-4.2 | <3.8 or >4.2 | Adjust covariates/filtering |
| **Genotype Error** | <0.5% | 0.5-1% | >1% | Exclude batches, stricter QC |
| **h² Standard Error** | <0.1 | 0.1-0.2 | >0.2 | Increase sample size |
| **Relatedness (max)** | <0.05 | 0.05-0.1 | >0.1 | Stricter filtering |
| **Number of Unrelated** | >5000 | 1000-5000 | <1000 | Collect more samples |

---

## Common QC Issues and Solutions

### Issue 1: High Inflation (> 4.2)

**Symptoms**:
- h²_full / mean(h²_quarters) > 4.2
- h² estimates are inflated

**Causes**:
- Population stratification
- Cryptic relatedness
- Residual confounding

**Solutions**:
1. Add more principal components (try 10, 20, 40 PCs)
2. Stricter relatedness filtering (--max-rel 0.025)
3. Include batch/study site as categorical covariate
4. Check for sample contamination
5. Verify ethnicity homogeneity

### Issue 2: Low Inflation (< 3.8)

**Symptoms**:
- h²_full / mean(h²_quarters) < 3.8
- h² estimates may be deflated

**Causes**:
- Over-correction with covariates
- Too strict relatedness filtering
- Model misspecification

**Solutions**:
1. Reduce number of principal components
2. Relax relatedness threshold (--max-rel 0.1)
3. Remove highly correlated covariates
4. Check phenotype quality

### Issue 3: High Genotype Error (> 1%)

**Symptoms**:
- Batch-specific h² is high
- Error rate > 1%

**Causes**:
- Systematic genotyping errors
- Batch effects
- Platform differences

**Solutions**:
1. Exclude problematic batches
2. Apply stricter call rate filter (> 99%)
3. Increase MAF threshold (> 0.01)
4. Use batch-specific QC
5. Consider regenotyping

### Issue 4: Negative Heritability

**Symptoms**:
- h² < 0 (e.g., -0.05)

**Causes**:
- Sampling variance (especially small N)
- Model misspecification
- Poor phenotype quality

**Solutions**:
1. If h² is slightly negative (-0.1 to 0): Likely sampling variance, report as h² ≈ 0
2. If h² is very negative (< -0.1): Check phenotype, covariates, kinship matrix
3. Increase sample size
4. Verify phenotype distribution (outliers, transformations)

---

## Debugging Tips

**Check kinship matrix**:
```bash
# View kinship summary
ldak6 --grm mykinship --stats
```

**Check phenotype distribution**:
```bash
# In R
hist(pheno$Y1)
summary(pheno$Y1)
```

**Verify covariate correlations**:
```bash
# In R
cor(covariates)
```

**Check for missing data**:
```bash
# Count missing phenotypes
grep -c "NA" phenotype.txt
```

---

## Related Documentation

- [LDAK Modules Overview](CLAUDE.md)
- [Kinship Process Reference](KINSHIP_REFERENCE.md)
- [Heritability Process Reference](HERITABILITY_REFERENCE.md)
- [LDAK QC Workflow](../../../workflows/ldak/CLAUDE.md)
- [Inflation Testing (bin/calc_inflation.R)](../../../bin/CLAUDE.md)
