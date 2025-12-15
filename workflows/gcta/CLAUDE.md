# GCTA Workflows

[Root Directory](../../CLAUDE.md) > [workflows](../CLAUDE.md) > **gcta**

## Change Log (Changelog)

### 2025-12-15
- Added GCTA Bivariate GREML workflows for genetic correlation estimation
- Added gcta_bivariate_greml.nf (single GRM) and gcta_bivariate_greml_ldms.nf (multi-GRM)

### 2025-12-13 09:41:58
- Initial documentation creation
- Documented GRM calculation, GREML, GREML-LDMS, and FastGWA workflows

---

## Module Responsibilities

GCTA (Genome-wide Complex Trait Analysis) workflows implement genetic relationship matrix (GRM) based methods for heritability estimation, association testing, and genetic correlation. The workflows support:

1. **GRM Calculation**: Parallelized genetic relationship matrix computation
2. **GREML**: Genomic-restricted maximum likelihood heritability estimation
3. **GREML-LDMS**: Partitioned heritability with LD-stratified models
4. **FastGWA**: Fast mixed model association testing with sparse GRM
5. **Bivariate GREML**: Genetic correlation estimation between two traits
6. **Bivariate GREML-LDMS**: Genetic correlation with LD-stratified GRMs

**Key Features**:
- Chromosome-parallelized GRM computation
- LD score-based SNP stratification
- Relatedness filtering (grm-cutoff 0.05)
- Sparse GRM for computational efficiency
- Support for quantitative and categorical covariates
- Bivariate analysis for genetic correlation

---

## Entry and Startup

### Primary Workflows

**1. GCTA_GRM** (`gcta_grm.nf`)
- Standalone GRM calculation workflow
- Used as a subworkflow by GREML and FastGWA
- Supports SNP group filtering for partitioned heritability

**2. GCTA_GREML** (`gcta_greml.nf`)
- Standard GREML heritability estimation
- Single-component variance estimation

**3. GCTA_GREML_LDMS** (`gcta_greml_ldms.nf`)
- Partitioned heritability with LD-stratified models
- Segments SNPs by LD scores into groups
- Multi-component variance estimation

**4. GCTA_FASTGWA** (`gcta_fastgwa.nf`)
- Fast genome-wide association testing
- Uses sparse GRM for scalability
- Chromosome-parallelized association tests

**5. GCTA_BIVARIATE_GREML** (`gcta_bivariate_greml.nf`)
- Genetic correlation estimation between two traits
- Uses single GRM (standard bivariate REML)
- Requires two phenotype column names

**6. GCTA_BIVARIATE_GREML_LDMS** (`gcta_bivariate_greml_ldms.nf`)
- Genetic correlation with LD-stratified GRMs
- Segments SNPs by LD scores, calculates separate GRMs
- Multi-component bivariate REML

### Invocation Pattern
```groovy
include { GCTA_GREML } from './workflows/gcta/gcta_greml'

GCTA_GREML(
    phenotypes_file,
    covariates_file,
    imputed_plink2_ch,
    nparts_gcta
)
```

---

## External Interfaces

### Input Channels

**GCTA_GRM**:
- `imputed_plink2_ch`: PLINK2 files `[chr_num, filename, pgen, psam, pvar, range]`
- `nparts_gcta`: Number of parallelization parts (default: 10)
- `snps_to_extract_ch`: Optional SNP group filters `[group_id, snp_list_file]`

**GCTA_GREML**:
- `phenotypes_file`: Path to phenotype file
- `covariates_file`: Path to covariate file (optional)
- `imputed_plink2_ch`: PLINK2 files
- `nparts_gcta`: GRM parallelization parameter

**GCTA_GREML_LDMS**:
- `phenotypes_file`: Phenotype file path
- `covariates_file`: Covariate file path
- `imputed_plink2_ch`: PLINK2 files
- `imputed_plink_ch`: PLINK1 files (for LD score calculation)
- `nparts_gcta`: GRM parallelization parameter

**GCTA_FASTGWA**:
- `imputed_plink2_ch`: PLINK2 files
- `phenotypes_file`: Phenotype file path
- `covariates_file`: Covariate file path
- `nparts_gcta`: GRM parallelization parameter
- `sparse_cutoff`: Sparse GRM cutoff (default: 0.05)

### Output Channels

**GCTA_GRM**:
- `grm_files`: Tuple `[snp_group, prefix, grm.id, grm.bin, grm.N.bin]`

**GCTA_GREML**:
- `reml_results`: REML output files (*.hsq)

**GCTA_GREML_LDMS**:
- `ld_scores`: LD score files per chromosome
- `reml_results`: Multi-component REML results

**GCTA_FASTGWA**:
- `fastgwa_results`: Association test results per chromosome

---

## Key Dependencies and Configuration

### Process Dependencies

**GCTA_GRM uses**:
- `modules/local/gcta/make_mpfiles.nf`: Create multi-part files per chromosome
- `modules/local/gcta/merge_mpfiles.nf`: Merge chromosome mpfiles
- `modules/local/gcta/make_grm_part.nf`: Calculate GRM partition
- `modules/local/gcta/merge_grm_parts.nf`: Merge GRM partitions
- `modules/local/gcta/adjust_grm.nf`: Adjust for incomplete tagging
- `modules/local/gcta/remove_related_subjects.nf`: Filter related individuals

**GCTA_GREML adds**:
- `modules/local/gcta/prepare_phenocov.nf`: Format phenotype/covariate files
- `modules/local/gcta/run_reml.nf`: Run REML analysis

**GCTA_GREML_LDMS adds**:
- `modules/local/gcta/calculate_ld_scores.nf`: Calculate LD scores
- `modules/local/gcta/merge_snp_groups.nf`: Merge SNP group files
- `modules/local/gcta/make_mgrm.nf`: Create multi-GRM file

**GCTA_FASTGWA adds**:
- `modules/local/gcta/make_bk_sparse.nf`: Create sparse GRM
- `modules/local/gcta/run_fastgwa_mlm.nf`: Run FastGWA-MLM

### Configuration Parameters

**GRM Calculation**:
- `params.nparts_gcta`: Number of GRM parts (default: 10)
  - Higher values = more parallelization but more I/O
  - Recommended: 10-20 for biobank-scale data

**GREML**:
- `params.phenotypes_filename`: Phenotype file path
- `params.covariates_filename`: Covariate file path
- `params.covariates_columns`: Covariate column names (comma-separated)
- `params.covariates_cat_columns`: Categorical covariate names

**GREML-LDMS**:
- All GREML parameters
- LD score calculation uses default 200kb window

**FastGWA**:
- All GREML parameters
- `params.gcta_sparse_cutoff`: Sparse GRM cutoff (default: 0.05)
  - Lower values = sparser matrix, faster computation
  - Higher values = more information retained

### Tool Requirements
- **GCTA v1.93+**: GRM, REML, FastGWA, LD scores
- **R with data.table**: SNP segmentation (`bin/segment_snp.R`)

---

## Data Models

### GRM File Structure
```
gcta_grm_0.grm.id       # Individual IDs (FID IID)
gcta_grm_0.grm.bin      # Binary GRM values
gcta_grm_0.grm.N.bin    # Number of SNPs per pair
```

**Channel Format**: `[snp_group, prefix, grm_id, grm_bin, grm_n_bin]`

### REML Output Structure
```
phenotype.hsq           # Heritability estimates
# Contains: V(G), V(e), V(G)/Vp (h2), logL, etc.
```

### FastGWA Output Structure
```
chr01.fastGWA           # Per-chromosome association results
# Columns: CHR, SNP, POS, A1, A2, N, AF1, BETA, SE, P
```

### LD Score Output
```
chr01_gcta_ld.score.ld  # LD scores per SNP
chr01_snp_group1.txt    # SNP list for group 1 (high LD)
chr01_snp_group2.txt    # SNP list for group 2 (medium LD)
chr01_snp_group3.txt    # SNP list for group 3 (low LD)
chr01_snp_group4.txt    # SNP list for group 4 (very low LD)
```

---

## Workflow Logic Details

### GRM Calculation Pipeline
```
1. MAKE_MPFILES: Create mpfiles for each chromosome
   → chr01.mpfile, chr02.mpfile, ...

2. MERGE_MPFILES: Combine all chromosome mpfiles
   → merged.mpfile

3. MAKE_GRM_PART: Calculate GRM parts in parallel
   → gcta_grm_0.part_10_1.grm.* ... gcta_grm_0.part_10_10.grm.*

4. MERGE_GRM_PARTS: Combine GRM parts
   → gcta_grm_0.grm.*

5. ADJUST_GRM: Adjust for incomplete tagging
   → gcta_grm_0.grm.* (adjusted)

6. REMOVE_RELATED_SUBJECTS: Filter related pairs
   → gcta_grm_0.grm.* (unrelated)
```

### GREML-LDMS SNP Stratification
```
1. CALCULATE_LD_SCORES: Calculate LD per chromosome
   → chr*.score.ld + chr*_snp_group*.txt

2. MERGE_SNP_GROUPS: Merge groups across chromosomes
   → snp_group1.txt, snp_group2.txt, ...

3. GCTA_GRM: Calculate separate GRM per group
   → gcta_grm_1.grm.*, gcta_grm_2.grm.*, ...

4. MAKE_MGRM: Create multi-GRM file
   → multi_grm.txt (list of GRM prefixes)

5. RUN_REML: Multi-component REML
   → phenotype.hsq (with partitioned variance)
```

---

## Testing and Quality

### Module Tests
- `tests/modules/local/gcta_greml.nf.test`: GREML workflow test
- `tests/modules/local/make_mgrm.nf.test`: Multi-GRM file creation
- `tests/modules/local/gcta/create_mpfiles_per_chrom.nf.test`: Mpfile creation
- `tests/modules/local/merge-mpfiles.nf.test`: Mpfile merging

### Test Data
- `tests/input/pipeline/chr*.{bed,bim,fam}`: Test genotype files
- `tests/input/pipeline/phenotype.txt`: Test phenotypes
- Minimal datasets for quick validation

### Expected Behavior
- GRM calculation should produce positive semi-definite matrix
- REML h2 estimates should be between 0 and 1
- Related individuals (>0.05) should be removed
- FastGWA should run faster than standard GWAS

---

## Usage Examples

### Standard GREML Heritability
```groovy
GCTA_GREML(
    file("phenotypes.txt"),
    file("covariates.txt"),
    imputed_plink2_ch,
    10  // nparts_gcta
)
```

### Partitioned Heritability (GREML-LDMS)
```groovy
GCTA_GREML_LDMS(
    file("phenotypes.txt"),
    file("covariates.txt"),
    imputed_plink2_ch,
    imputed_plink_ch,
    10  // nparts_gcta
)
```

### FastGWA Association Testing
```groovy
GCTA_FASTGWA(
    imputed_plink2_ch,
    file("phenotypes.txt"),
    file("covariates.txt"),
    10,   // nparts_gcta
    0.05  // sparse_cutoff
)
```

### Bivariate GREML Genetic Correlation (Single GRM)
```groovy
GCTA_BIVARIATE_GREML(
    file("phenotypes.txt"),  // Must contain both phenotypes
    file("covariates.txt"),
    imputed_plink2_ch,
    10,        // nparts_gcta
    "height",  // phenotype1_name
    "weight"   // phenotype2_name
)
```

### Bivariate GREML-LDMS Genetic Correlation (LD-Stratified)
```groovy
GCTA_BIVARIATE_GREML_LDMS(
    file("phenotypes.txt"),
    file("covariates.txt"),
    imputed_plink2_ch,
    imputed_plink_ch,  // For LD score calculation
    10,        // nparts_gcta
    "height",  // phenotype1_name
    "weight"   // phenotype2_name
)
```

---

## Frequently Asked Questions (FAQ)

**Q: How do I choose the optimal nparts_gcta value?**
A: Start with 10. Increase to 20-50 for very large datasets (>100k samples). Monitor I/O performance.

**Q: Why does GRM calculation take so long?**
A: GRM is O(N^2) in sample size. Use parallelization (nparts_gcta) and ensure adequate CPU/memory resources.

**Q: What does "adjusting for incomplete tagging" mean?**
A: GCTA adjusts the GRM to account for SNPs not fully capturing causal variants. This is standard practice.

**Q: Can I skip related individual removal?**
A: Not recommended. Related individuals violate GREML assumptions and inflate heritability estimates.

**Q: What's the difference between GREML and GREML-LDMS?**
A: GREML assumes all SNPs contribute equally. GREML-LDMS stratifies SNPs by LD and tests if high-LD regions have higher per-SNP heritability.

**Q: Why use FastGWA instead of standard GWAS?**
A: FastGWA is orders of magnitude faster for large samples (>50k) while producing nearly identical results.

**Q: What sparse_cutoff value should I use?**
A: 0.05 is standard (keeps only GRM values >0.05). Lower = faster but less accurate. Higher = slower but more accurate.

**Q: Can I use GCTA with binary traits?**
A: Yes, but GREML assumes normally distributed residuals. Consider liability-scale transformation or use BOLT-LMM for case-control.

---

## Workflow Files

- `gcta_grm.nf`: GRM calculation subworkflow (78 lines)
- `gcta_greml.nf`: Standard GREML workflow (51 lines)
- `gcta_greml_ldms.nf`: LD-stratified GREML workflow (88 lines)
- `gcta_fastgwa.nf`: FastGWA association testing (60 lines)
- `gcta_bivariate_greml.nf`: Bivariate GREML genetic correlation (70 lines)
- `gcta_bivariate_greml_ldms.nf`: Bivariate GREML-LDMS genetic correlation (110 lines)

---

## Related Documentation

- [GCTA Modules](../../modules/local/gcta/CLAUDE.md)
- [Root Documentation](../../CLAUDE.md)
- [Workflows Overview](../CLAUDE.md)
- [GCTA Official Docs](https://yanglab.westlake.edu.cn/software/gcta/)
