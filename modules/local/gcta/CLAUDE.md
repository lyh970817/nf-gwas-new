# GCTA Modules

[Root Directory](../../../CLAUDE.md) > [modules/local](../CLAUDE.md) > **gcta**

## Change Log (Changelog)

### 2025-12-15
- Added bivariate GREML modules for genetic correlation estimation
- Added PREPARE_PHENOCOV_BIVARIATE, RUN_BIVARIATE_REML, RUN_BIVARIATE_REML_LDMS

### 2025-12-13 09:41:58
- Initial documentation creation
- Documented all GCTA process modules for GRM, REML, FastGWA, and LD scores

---

## Module Responsibilities

GCTA (Genome-wide Complex Trait Analysis) process modules implement atomic tasks for genetic relationship matrix (GRM) calculation, heritability estimation, genetic correlation, and association testing. These processes enable:

**GRM Calculation**:
- Parallelized GRM computation via multi-part files
- Chromosome-specific and genome-wide matrices
- Relatedness filtering and GRM adjustment

**Heritability Estimation**:
- REML variance component analysis
- LD score-based SNP stratification
- Multi-component heritability models

**Genetic Correlation**:
- Bivariate REML for genetic correlation between two traits
- Single GRM and multi-GRM (LD-stratified) approaches

**Association Testing**:
- FastGWA mixed model tests
- Sparse GRM for computational efficiency

---

## Module Index

### GRM Calculation Modules

| Module | Purpose | Input | Output |
|--------|---------|-------|--------|
| `make_mpfiles.nf` | Create multi-part files per chromosome | PLINK2 files | .mpfile per chr |
| `merge_mpfiles.nf` | Merge chromosome mpfiles | All .mpfile files | Single merged.mpfile |
| `make_grm_part.nf` | Calculate GRM partition | mpfile, part number | .grm.bin/id/N.bin |
| `merge_grm_parts.nf` | Merge GRM partitions | All GRM parts | Merged GRM files |
| `adjust_grm.nf` | Adjust for incomplete tagging | GRM files | Adjusted GRM |
| `remove_related_subjects.nf` | Filter related individuals | GRM files | Unrelated GRM |
| `make_mgrm.nf` | Create multi-GRM file | List of GRM prefixes | .mgrm file |

### REML and FastGWA Modules

| Module | Purpose | Input | Output |
|--------|---------|-------|--------|
| `prepare_phenocov.nf` | Format phenotype/covariate files | Raw pheno/covar | No-header versions |
| `run_reml.nf` | REML variance estimation | GRM, phenotypes | .hsq results |
| `run_fastgwa_mlm.nf` | FastGWA association test | Sparse GRM, genotypes | .fastGWA results |
| `make_bk_sparse.nf` | Create sparse GRM | Dense GRM, cutoff | Sparse GRM |

### Bivariate REML Modules (Genetic Correlation)

| Module | Purpose | Input | Output |
|--------|---------|-------|--------|
| `prepare_phenocov_bivariate.nf` | Format bivariate phenotypes | Phenotype file, two trait names | Bivariate phenotype file, mpheno indices |
| `run_bivariate_reml.nf` | Bivariate REML (single GRM) | GRM, phenotypes | .hsq with genetic correlation |
| `run_bivariate_reml_ldms.nf` | Bivariate REML (multi-GRM) | mGRM file, phenotypes | .hsq with genetic correlation |

### LD Score Modules

| Module | Purpose | Input | Output |
|--------|---------|-------|--------|
| `calculate_ld_scores.nf` | Calculate LD scores and segment SNPs | PLINK files | .score.ld, SNP groups |
| `merge_snp_groups.nf` | Merge SNP groups across chromosomes | Group files | Merged group files |

---

## Process Details

### MAKE_MPFILES

**Purpose**: Create multi-part files for each chromosome (enables parallelized GRM calculation)

**Inputs**:
- `tuple val(chr_num), val(filename), path(pgen), path(psam), path(pvar), val(range)`: PLINK2 files

**Outputs**:
- `tuple val(filename), path("${filename}.mpfile")`: mpfile for this chromosome

**Script Logic**:
```bash
plink2 \
    --pfile ${filename} \
    --make-grm-bin \
    --out ${filename}
mv ${filename}.grm.bin.mpfile ${filename}.mpfile
```

**Key Notes**:
- PLINK2 generates .grm.bin.mpfile during GRM creation
- Renamed to .mpfile for clarity
- One mpfile per chromosome

---

### MERGE_MPFILES

**Purpose**: Combine all chromosome mpfiles into single merged file

**Inputs**:
- `path mpfile_parts`: All chromosome .mpfile files

**Outputs**:
- `path "merged.mpfile"`: Combined mpfile

**Script Logic**:
```bash
cat ${mpfile_parts.join(' ')} > merged.mpfile
```

**Key Notes**:
- Simple concatenation of text files
- Required for genome-wide GRM calculation
- Enables GCTA to process all chromosomes simultaneously

---

### MAKE_GRM_PART

**Purpose**: Calculate one partition of the GRM matrix

**Inputs**:
- `path mpfile`: Merged mpfile
- `tuple val(part_gcta_job), val(nparts_gcta), val(snp_group), path(snp_group_file)`: Partition parameters
- `path plink2_files`: All PLINK2 files

**Outputs**:
- `tuple val(nparts_gcta), val(snp_group), path(...grm.id), path(...grm.bin), path(...grm.N.bin)`: GRM partition

**Script Logic**:
```bash
gcta \
    --mpfile ${mpfile} \
    --make-grm-part ${nparts_gcta} ${part_gcta_job} \
    ${extract_cmd} \
    --maf 0.01 \
    --thread-num ${task.cpus} \
    --out ${out}
```

**Key Parameters**:
- `--make-grm-part N M`: Calculate part M of N total parts
- `--extract`: Optional SNP group filtering (for GREML-LDMS)
- `--maf 0.01`: Filter rare variants

**Resource Notes**:
- Memory scales with sample size: ~2 GB per 10k samples
- CPU parallelization within partition

---

### MERGE_GRM_PARTS

**Purpose**: Merge all GRM partitions into single matrix

**Inputs**:
- `tuple val(nparts_gcta), val(snp_group), path(grm_id_files), path(grm_bin_files), path(grm_n_files)`: All partitions

**Outputs**:
- `tuple val(snp_group), val(prefix), path(...grm.id), path(...grm.bin), path(...grm.N.bin)`: Merged GRM

**Script Logic**:
```bash
# Create list of GRM prefixes
ls gcta_grm_${snp_group}.part_${nparts_gcta}_*.grm.id \
    | sed 's/.grm.id//g' > grm_parts_list.txt

# Merge using GCTA
gcta \
    --mgrm grm_parts_list.txt \
    --make-grm \
    --out ${prefix}
```

**Key Notes**:
- GCTA requires .id/.bin/.N.bin files for each partition
- Creates single merged GRM from all parts
- Prefix naming: `gcta_grm_${snp_group}`

---

### ADJUST_GRM

**Purpose**: Adjust GRM for incomplete tagging of causal SNPs

**Inputs**:
- `tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)`: GRM files

**Outputs**:
- `tuple val(snp_group), val(prefix), path(...grm.id), path(...grm.bin), path(...grm.N.bin)`: Adjusted GRM

**Script Logic**:
```bash
gcta \
    --grm ${prefix} \
    --grm-adj 0 \
    --make-grm \
    --out ${prefix}
```

**Key Notes**:
- `--grm-adj 0`: Adjusts for sampling of tagged SNPs
- Standard practice in GREML analysis
- Overwrites original GRM files

---

### REMOVE_RELATED_SUBJECTS

**Purpose**: Filter out related individuals (kinship > 0.05)

**Inputs**:
- `tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)`: GRM files

**Outputs**:
- `tuple val(snp_group), val(prefix), path(...grm.id), path(...grm.bin), path(...grm.N.bin)`: Unrelated GRM

**Script Logic**:
```bash
gcta \
    --grm ${prefix} \
    --grm-cutoff 0.05 \
    --make-grm \
    --out ${prefix}
```

**Key Parameters**:
- `--grm-cutoff 0.05`: Remove pairs with kinship > 0.05
- Iteratively removes individuals to maximize remaining sample

**Key Notes**:
- Essential for unbiased GREML estimates
- Removes related pairs, not just duplicates
- Typical sample reduction: 5-10% for population cohorts

---

### MAKE_MGRM

**Purpose**: Create multi-GRM file listing all GRM prefixes

**Inputs**:
- `path grm_prefixes`: List of GRM prefix strings

**Outputs**:
- `path "multi_grm.txt"`: Multi-GRM file

**Script Logic**:
```bash
# Write each prefix to multi_grm.txt
echo "${grm_prefixes.join('\n')}" > multi_grm.txt
```

**Key Notes**:
- Used for multi-component GREML (GREML-LDMS)
- Plain text file, one GRM prefix per line
- GCTA reads with `--mgrm multi_grm.txt`

---

### PREPARE_PHENOCOV

**Purpose**: Format phenotype and covariate files for GCTA

**Inputs**:
- `path phenotype_file`: Raw phenotype file
- `path covariate_file`: Raw covariate file

**Outputs**:
- `path "phenotypes_noheader.txt"`: Phenotypes without header
- `path "covariates_quant_noheader.txt"`: Quantitative covariates (optional)
- `path "covariates_cat_noheader.txt"`: Categorical covariates (optional)

**Script Logic**:
```bash
# Remove header from phenotypes
tail -n +2 ${phenotype_file} > phenotypes_noheader.txt

# Extract quantitative covariates
Rscript ${projectDir}/bin/extract_columns.R \\
    ${covariate_file} \\
    "${quant_covar_cols}" \\
    covariates_quant_noheader.txt

# Extract categorical covariates
Rscript ${projectDir}/bin/extract_columns.R \\
    ${covariate_file} \\
    "${cat_covar_cols}" \\
    covariates_cat_noheader.txt
```

**Key Notes**:
- GCTA requires files without headers
- Separates quantitative and categorical covariates
- Uses R script for column extraction

---

### RUN_REML

**Purpose**: Execute REML variance component estimation

**Inputs**:
- `tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)`: GRM files
- `path phenotypes_file`: Phenotype file (no header)
- `path qcovariates_file`: Quantitative covariates (optional)
- `path covariates_file`: Categorical covariates (optional)

**Outputs**:
- `path "*.hsq"`: REML results

**Script Logic**:
```bash
gcta \\
    --reml \\
    --grm ${prefix} \\
    --pheno ${phenotypes_file} \\
    ${qcovar_param} \\
    ${covar_param} \\
    --out ${out} \\
    --thread-num ${task.cpus}
```

**Key Parameters**:
- `--reml`: REML estimation mode
- `--qcovar`: Quantitative covariates
- `--covar`: Categorical covariates

**publishDir**: `${params.pubDir}/gcta_greml`

---

### RUN_FASTGWA_MLM

**Purpose**: Execute FastGWA mixed model association test

**Inputs**:
- `tuple val(chr_num), val(filename), path(pgen), path(psam), path(pvar), val(range)`: PLINK2 files
- `tuple val(prefix), path(grm_bin), path(grm_id)`: Sparse GRM
- `path phenotypes_file`, `path qcovariates_file`, `path covariates_file`

**Outputs**:
- `tuple val(filename), path("${filename}.fastGWA")`: Association results

**Script Logic**:
```bash
gcta \\
    --pfile ${filename} \\
    --grm-sparse ${prefix} \\
    --fastGWA-mlm \\
    --pheno ${phenotypes_file} \\
    ${qcovar_param} \\
    ${covar_param} \\
    --out ${filename} \\
    --threads ${task.cpus}
```

**Key Parameters**:
- `--fastGWA-mlm`: Mixed linear model mode
- `--grm-sparse`: Use sparse GRM for efficiency

**publishDir**: `${params.pubDir}/gcta_fastgwa`

---

### MAKE_BK_SPARSE

**Purpose**: Create sparse GRM for FastGWA

**Inputs**:
- `tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)`: Dense GRM
- `val sparse_cutoff`: Sparsity threshold (default: 0.05)

**Outputs**:
- `tuple val(prefix), path("${prefix}.grm.sp"), path("${prefix}.grm.sp.id")`: Sparse GRM

**Script Logic**:
```bash
gcta \\
    --grm ${prefix} \\
    --make-bK-sparse ${sparse_cutoff} \\
    --out ${prefix}
```

**Key Notes**:
- Keeps only GRM values > cutoff
- Dramatically reduces memory/computation for large N
- Typical sparsity: 99%+ for cutoff 0.05

---

### CALCULATE_LD_SCORES

**Purpose**: Calculate LD scores and segment SNPs into groups

**Inputs**:
- `tuple val(chr_num), val(filename), path(bed), path(bim), path(fam), val(range)`: PLINK files

**Outputs**:
- `tuple val(filename), path("${filename}_gcta_ld.score.ld")`: LD scores
- `tuple val(filename), path("${filename}_snp_group*.txt")`: SNP group files

**Script Logic**:
```bash
# Calculate LD scores
gcta \\
    --bfile ${filename} \\
    --ld-score-region 200 \\
    --out ${filename}_gcta_ld \\
    --thread-num ${task.cpus}

# Segment SNPs by LD score
Rscript ${projectDir}/bin/segment_snp.R \\
    ${filename}_gcta_ld.score.ld \\
    ${filename}
```

**Key Parameters**:
- `--ld-score-region 200`: 200kb window for LD calculation

**Output Files**:
```
chr01_gcta_ld.score.ld   # LD score per SNP
chr01_snp_group1.txt     # High LD SNPs
chr01_snp_group2.txt     # Medium LD SNPs
chr01_snp_group3.txt     # Low LD SNPs
chr01_snp_group4.txt     # Very low LD SNPs
```

**publishDir**: `${params.pubDir}/gcta_ldms`

---

### MERGE_SNP_GROUPS

**Purpose**: Merge SNP group files across chromosomes

**Inputs**:
- `tuple val(group_num), path(snp_group_files)`: Group files from all chromosomes

**Outputs**:
- `tuple val(group_num), path("snp_group_${group_num}.txt")`: Merged group file

**Script Logic**:
```bash
cat ${snp_group_files.join(' ')} > snp_group_${group_num}.txt
```

**Key Notes**:
- Combines same-group SNPs from all chromosomes
- Enables genome-wide partitioned heritability
- Used in GREML-LDMS workflow

---

### PREPARE_PHENOCOV_BIVARIATE

**Purpose**: Prepare phenotype and covariate files for bivariate REML analysis (genetic correlation)

**Inputs**:
- `path phenotypes_file`: Raw phenotype file with header
- `path covariates_file`: Raw covariate file (optional)
- `val phenotype1_name`: Name of first phenotype column
- `val phenotype2_name`: Name of second phenotype column

**Outputs**:
- `path "phenotypes_bivariate.txt", emit: phenotypes_file`: Bivariate phenotypes (FID IID Y1 Y2, no header)
- `path "mpheno_indices.txt", emit: mpheno_indices`: File containing "1\n2\n" for --mpheno flag
- `path "*.quant.noheader.txt", emit: covariates_quant_noheader`: Quantitative covariates (optional)
- `path "*.cat.noheader.txt", emit: covariates_cat_noheader`: Categorical covariates (optional)

**Script Logic**:
```bash
# Extract two phenotypes using R script
Rscript ${projectDir}/bin/prepare_bivariate_phenotypes.R \\
    ${phenotypes_file} \\
    ${phenotype1_name} \\
    ${phenotype2_name} \\
    phenotypes_bivariate.txt \\
    mpheno_indices.txt

# Handle covariates (same logic as prepare_phenocov.nf)
```

**Key Notes**:
- Uses R script for flexible column extraction
- Missing values converted to -9 (GCTA format)
- mpheno_indices.txt enables GCTA --mpheno 1 2 flag
- publishDir: `${params.pubDir}/gcta_bivariate_greml`

---

### RUN_BIVARIATE_REML

**Purpose**: Execute bivariate REML for genetic correlation estimation (single GRM)

**Inputs**:
- `tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)`: GRM files
- `path phenotypes_file`: Bivariate phenotype file (no header)
- `path qcovariates_file`: Quantitative covariates (optional)
- `path covariates_file`: Categorical covariates (optional)

**Outputs**:
- `path "*.hsq", emit: bivariate_results`: Bivariate REML results with genetic correlation

**Script Logic**:
```bash
gcta \\
    --reml-bivar 1 2 \\
    --grm ${prefix} \\
    --pheno ${phenotypes_file} \\
    ${qcovar_param} \\
    ${covar_param} \\
    --out ${out} \\
    --thread-num ${task.cpus}
```

**Key Parameters**:
- `--reml-bivar 1 2`: Bivariate REML mode with phenotype columns 1 and 2
- `--qcovar`: Quantitative covariates (optional)
- `--covar`: Categorical covariates (optional)

**Output .hsq Contents**:
```
Source           Variance    SE
V(G1)            0.45        0.08    # Genetic variance trait 1
V(G2)            0.38        0.07    # Genetic variance trait 2
C(G1,G2)         0.12        0.03    # Genetic covariance
rG               0.35        0.08    # Genetic correlation (key result)
...
```

**publishDir**: `${params.pubDir}/gcta_bivariate_greml`

---

### RUN_BIVARIATE_REML_LDMS

**Purpose**: Execute bivariate REML with multiple LD-stratified GRMs (LDMS approach)

**Inputs**:
- `path mgrm_file`: Multi-GRM file listing all GRM prefixes
- `path grm_files`: All GRM files (collected)
- `path phenotypes_file`: Bivariate phenotype file (no header)
- `path qcovariates_file`: Quantitative covariates (optional)
- `path covariates_file`: Categorical covariates (optional)

**Outputs**:
- `path "*.hsq", emit: bivariate_results`: Multi-component bivariate REML results

**Script Logic**:
```bash
gcta \\
    --reml-bivar 1 2 \\
    --mgrm ${mgrm_file} \\
    --pheno ${phenotypes_file} \\
    ${qcovar_param} \\
    ${covar_param} \\
    --reml-bivar-no-constrain \\
    --out ${out} \\
    --thread-num ${task.cpus}
```

**Key Parameters**:
- `--reml-bivar 1 2`: Bivariate REML mode with phenotype columns 1 and 2
- `--mgrm`: Multiple GRMs (one per LD-stratified SNP group)
- `--reml-bivar-no-constrain`: Allows estimates outside standard bounds (recommended for multi-GRM)

**Key Notes**:
- Used for partitioned genetic correlation analysis
- Typically 4 GRMs from LD score stratification
- Provides per-component genetic correlation estimates
- publishDir: `${params.pubDir}/gcta_bivariate_greml_ldms`

---

## Testing and Quality

### Module Tests
- `tests/modules/local/gcta_greml.nf.test`: GREML workflow test
- `tests/modules/local/make_mgrm.nf.test`: Multi-GRM file creation
- `tests/modules/local/gcta/create_mpfiles_per_chrom.nf.test`: Mpfile creation
- `tests/modules/local/merge-mpfiles.nf.test`: Mpfile merging
- `tests/modules/local/gcta/prepare_phenocov_bivariate.nf.test`: Bivariate phenotype preparation
- `tests/modules/local/gcta/run_bivariate_reml.nf.test`: Single GRM bivariate REML
- `tests/modules/local/gcta/run_bivariate_reml_ldms.nf.test`: Multi-GRM bivariate REML

### Expected Outputs
- GRM values should be between -1 and 1
- REML h2 should be between 0 and 1
- FastGWA p-values should follow uniform distribution under null
- LD scores should be positive
- Genetic correlation (rG) should be between -1 and 1

---

## Frequently Asked Questions (FAQ)

**Q: Why create mpfiles instead of using PLINK files directly?**
A: Mpfiles enable parallelized GRM calculation. Each partition reads the same mpfile to compute its subset of the GRM.

**Q: What is the optimal nparts_gcta value?**
A: 10-20 for most datasets. Higher values = more parallelization but more I/O overhead.

**Q: Why adjust the GRM?**
A: Adjustment accounts for the fact that genotyped SNPs imperfectly tag causal variants. This is standard practice in GREML.

**Q: What does grm-cutoff 0.05 mean?**
A: Removes individuals with genetic similarity > 0.05 (approximately 3rd-degree relatives or closer).

**Q: Can I skip related individual removal?**
A: Not recommended. Related individuals violate GREML assumptions and inflate heritability estimates.

**Q: Why separate quantitative and categorical covariates?**
A: GCTA handles them differently: `--qcovar` for continuous, `--covar` for categorical (dummy-coded).

**Q: What sparse_cutoff should I use for FastGWA?**
A: 0.05 is standard. Lower = faster but less accurate. Higher = slower but more accurate.

**Q: How do I interpret LD scores?**
A: Higher LD score = SNP tags more of the genome. Used to partition SNPs by LD burden in GREML-LDMS.

**Q: What is bivariate REML used for?**
A: Bivariate REML estimates genetic correlation (rG) between two traits. A positive rG indicates shared genetic factors influence both traits in the same direction.

**Q: When should I use bivariate REML-LDMS vs. standard bivariate REML?**
A: Use LDMS when you want to partition genetic correlation by LD (to test if genetic correlation is driven by high-LD or low-LD variants). Standard bivariate REML is faster and sufficient for most applications.

**Q: What does --reml-bivar-no-constrain do?**
A: It allows variance and correlation estimates outside the standard bounds (0-1 for variance proportions, -1 to 1 for correlation). Recommended for multi-GRM analyses where numerical constraints can cause convergence issues.

---

## Process Files Summary

**GRM Calculation**: 7 processes (148 lines total)
**REML/FastGWA**: 4 processes (87 lines total)
**Bivariate REML**: 3 processes (genetic correlation)
**LD Scores**: 2 processes (49 lines total)

---

## Related Documentation

- [GCTA Workflows](../../../workflows/gcta/CLAUDE.md)
- [Modules Overview](../CLAUDE.md)
- [Root Documentation](../../../CLAUDE.md)
- [GCTA Official Docs](https://yanglab.westlake.edu.cn/software/gcta/)
