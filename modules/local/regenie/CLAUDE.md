# REGENIE Modules

[Root Directory](../../../CLAUDE.md) > [modules/local](../CLAUDE.md) > **regenie**

## Change Log (Changelog)

### 2025-12-13 09:41:58
- Initial documentation creation
- Documented all REGENIE process modules for Step 1 and Step 2

---

## Module Responsibilities

REGENIE process modules implement the atomic tasks for the two-step whole genome regression method. These processes are composed by workflows to enable:

**Step 1 Processes**:
- Whole genome regression model building
- Prediction file generation with leave-one-chromosome-out (LOCO)
- Support for chunked execution for memory efficiency

**Step 2 Processes**:
- Single-variant association testing
- Gene-based burden and SKAT tests
- Interaction testing (GxE, GxG)

Each module represents a single computational task with explicit inputs, outputs, and resource requirements.

---

## Module Index

| Module | Purpose | Input | Output | Resource Label |
|--------|---------|-------|--------|----------------|
| `regenie_step1_run.nf` | Standard Step 1 execution | PLINK genotypes, phenotypes, covariates | Predictions, LOCO files | Default |
| `regenie_step1_split.nf` | Split genotypes for chunking | PLINK genotypes, phenotypes | Chunk master file, SNP lists | Default |
| `regenie_step1_run_chunk.nf` | Run Step 1 on single chunk | Chunk files, genotypes | Chunk predictions | Default |
| `regenie_step1_merge_chunks.nf` | Merge chunk predictions | All chunk outputs | Merged predictions | Default |
| `regenie_step2_run.nf` | Single-variant tests | PLINK2/VCF, Step 1 predictions | Association results | Default |
| `regenie_step2_run_gene_tests.nf` | Gene-based tests | PLINK2/VCF, annotations, masks | Gene test results, mask files | Default |

---

## Process Details

### REGENIE_STEP1_RUN

**Purpose**: Execute standard REGENIE Step 1 without chunking

**Inputs**:
- `tuple val(genotyped_plink_filename), path(genotyped_plink_file)`: PLINK files
- `path phenotypes_file`: Phenotype file
- `path covariates_file`: Covariate file (optional)
- `path condition_list_file`: Conditional SNP list (optional)

**Outputs**:
- `path "regenie_step1_out*"`: All Step 1 output files (predictions, LOCO)
- `path "regenie_step1_out.log"`: Log file

**Key Parameters**:
- `--bsize ${params.regenie_bsize_step1}`: Block size (default: 1000)
- `--lowmem`: Use low-memory mode if enabled
- `--force-step1`: Force Step 1 even with >1M variants
- `--bt`: Binary trait flag
- `--threads ${task.cpus}`: CPU parallelization

**Script Logic**:
```bash
regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --phenoFile ${phenotypes_file} \
    --phenoColList ${params.phenotypes_columns} \
    --bsize ${params.regenie_bsize_step1} \
    --out regenie_step1_out
```

**publishDir**: `${params.pubDir}/logs` (log files only)

---

### REGENIE_STEP1_SPLIT

**Purpose**: Split genotypes into chunks for parallel Step 1 execution

**Inputs**:
- `tuple val(genotyped_plink_filename), path(genotyped_plink_file)`: PLINK files
- `path phenotypes_file`, `path covariates_file`, `path condition_list_file`

**Outputs**:
- `tuple path("chunks.master"), path("chunks*.snplist"), ...`: Master file + SNP lists + all input files
- `path("chunks.master")`: Master file separately emitted

**Key Parameters**:
- `--split-l0 chunks,${params.genotypes_prediction_chunks}`: Split into N chunks

**Script Logic**:
```bash
regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --split-l0 chunks,${params.genotypes_prediction_chunks} \
    --out chunks
```

**Output Files**:
```
chunks.master          # Master file listing chunks
chunks1.snplist        # SNPs for chunk 1
chunks2.snplist        # SNPs for chunk 2
...
```

---

### REGENIE_STEP1_RUN_CHUNK

**Purpose**: Execute Step 1 on a single chunk

**Inputs**:
- `tuple val(chunk_num), path("chunks.master"), path("chunks*.snplist"), ...`: Chunk-specific data

**Outputs**:
- `path "regenie_step1_out_${chunk_num}_*.loco.gz"`: LOCO predictions for this chunk
- `path "regenie_step1_out_${chunk_num}.log"`: Chunk log

**Key Parameters**:
- `--run-l0 chunks.master,${chunk_num}`: Run specific chunk

**Script Logic**:
```bash
regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --run-l0 chunks.master,${chunk_num} \
    --out regenie_step1_out_${chunk_num}
```

---

### REGENIE_STEP1_MERGE_CHUNKS

**Purpose**: Merge predictions from all chunks into final Step 1 output

**Inputs**:
- `path master_file`: Chunks master file
- `tuple val(genotyped_plink_filename), path(genotyped_plink_file)`: Original genotypes
- `path chunk_out`: All chunk LOCO files
- `path phenotypes_file`, `path covariates_file`, `path condition_list_file`

**Outputs**:
- `path "regenie_step1_out*"`: Merged Step 1 outputs
- `path "regenie_step1_out_*.loco.gz"`: Merged LOCO files (for concat)
- `path "regenie_step1_out.log"`: Merge log

**Key Parameters**:
- `--run-l1 ${master_file}`: Merge all chunks

**Script Logic**:
```bash
regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --run-l1 ${master_file} \
    --out regenie_step1_out
```

---

### REGENIE_STEP2_RUN

**Purpose**: Execute single-variant association tests

**Inputs**:
- `path step1_out`: Step 1 prediction files
- `tuple val(chr_num), val(filename), path(plink2_pgen_file), ...`: PLINK2 genotypes
- `val assoc_format`: Format (vcf/pgen)
- `path phenotypes_file`, `path sample_file`, `path covariates_file`, `path condition_list_file`

**Outputs**:
- `tuple val(filename), path("*regenie.gz"), path("*regenie.Ydict")`: Main results
- `tuple val(filename), path("*regenie.gz")`: Interaction results (optional)
- `path "${filename}*.log"`: Log files

**Key Parameters**:
- `--bsize ${params.regenie_bsize_step2}`: Block size (default: 400)
- `--test ${params.regenie_test}`: Test type (additive/recessive/dominant)
- `--firth`: Use Firth correction for binary traits
- `--approx`: Use approximate Firth
- `--minMAC ${params.regenie_min_mac}`: Minimum minor allele count
- `--minINFO ${params.regenie_min_imputation_score}`: Minimum INFO score
- `--interaction`: GxE covariate
- `--interaction-snp`: GxG SNP
- `--range ${chr_num}`: Chromosome-specific testing

**Script Logic**:
```bash
regenie \
    --step 2 \
    --pgen ${filename} \
    --phenoFile ${phenotypes_file} \
    --pred regenie_step1_out_pred.list \
    --bsize ${params.regenie_bsize_step2} \
    --minMAC ${params.regenie_min_mac} \
    --range ${chr_num} \
    --out ${output_name}
```

**publishDir**: `${params.pubDir}/logs` (log files only)

---

### REGENIE_STEP2_RUN_GENE_TESTS

**Purpose**: Execute gene-based burden and variance-component tests

**Inputs**:
- `path step1_out`: Step 1 predictions
- `tuple val(chr_num), val(filename), path(...plink files)`: Genotype data
- `path regenie_gene_anno_file`: Annotation file (SNP to gene mapping)
- `path regenie_gene_setlist_file`: Set list (gene to set mapping)
- `path regenie_gene_masks_file`: Mask definitions (AAF thresholds, test types)
- Other standard inputs (phenotypes, covariates, etc.)

**Outputs**:
- `tuple val(filename), path("*regenie.gz")`: Gene test results
- `path "${filename}.log"`: Log file
- `path "${filename}_masks*"`: Mask files (SNP lists, optionally PLINK bed/bim/fam)

**Key Parameters**:
- `--anno-file ${regenie_gene_anno_file}`: SNP-to-gene annotation
- `--set-list ${regenie_gene_setlist_file}`: Gene sets
- `--mask-def ${regenie_gene_masks_file}`: Mask definitions
- `--vc-tests ${params.regenie_gene_test}`: Test types (SKAT, ACAT, etc.)
- `--aaf-bins ${params.regenie_gene_aaf}`: AAF thresholds
- `--build-mask ${params.regenie_gene_build_mask}`: Mask construction (max/sum/comphet)
- `--write-mask`: Output mask files
- `--write-mask-snplist`: Output SNP lists per mask
- `--check-burden-files`: Validate input files

**Script Logic**:
```bash
regenie \
    --step 2 \
    --pgen ${filename} \
    --phenoFile ${phenotypes_file} \
    --pred regenie_step1_out_pred.list \
    --anno-file ${regenie_gene_anno_file} \
    --set-list ${regenie_gene_setlist_file} \
    --mask-def ${regenie_gene_masks_file} \
    --vc-tests ${params.regenie_gene_test} \
    --out ${filename}
```

**publishDir**:
- `${params.pubDir}/logs`: Log files
- `${params.pubDir}/masks`: Mask files and SNP lists

---

## Data Flow Patterns

### Standard Step 1 Workflow
```
genotyped_plink_ch → REGENIE_STEP1_RUN → regenie_step1_out
                                        → regenie_step1_out_pred.list
                                        → regenie_step1_out_*.loco.gz
```

### Chunked Step 1 Workflow
```
genotyped_plink_ch → REGENIE_STEP1_SPLIT → chunks.master + chunks*.snplist

chunks → Channel.of(1..N) → REGENIE_STEP1_RUN_CHUNK (parallel)
                           → chunk_1_*.loco.gz, chunk_2_*.loco.gz, ...

all chunks → REGENIE_STEP1_MERGE_CHUNKS → regenie_step1_out (merged)
```

### Step 2 Single-Variant
```
step1_out + imputed_plink2_ch → REGENIE_STEP2_RUN → chr01_PHENO.regenie.gz
                                                    → chr02_PHENO.regenie.gz
                                                    → ...
```

### Step 2 Gene-Based
```
step1_out + imputed_plink2_ch + annotations → REGENIE_STEP2_RUN_GENE_TESTS
                                            → chr01_gene_PHENO.regenie.gz
                                            → chr01_masks.snplist
                                            → chr01_masks.bed/bim/fam (if --write-mask)
```

---

## Testing and Quality

### Module Tests
- `tests/modules/local/regenie_step1.nf.test`: Step 1 standard and chunked modes
- `tests/modules/local/regenie_step2.nf.test`: Single-variant tests
- `tests/modules/local/regenie_step2_gene_tests.nf.test`: Gene-based tests

### Test Data
- `tests/input/pipeline/example.{bed,bim,fam}`: Small genotyped dataset
- `tests/input/pipeline/chr*.vcf.gz`: Minimal imputed VCFs
- `tests/input/pipeline/gene_based_tests_regenie/`: Gene test inputs

### Running Tests
```bash
# Test Step 1
nf-test test tests/modules/local/regenie_step1.nf.test

# Test Step 2
nf-test test tests/modules/local/regenie_step2.nf.test

# Test gene-based
nf-test test tests/modules/local/regenie_step2_gene_tests.nf.test
```

---

## Usage Examples

### Standard Step 1
```groovy
REGENIE_STEP1_RUN(
    tuple("example", [file("example.bed"), file("example.bim"), file("example.fam")]),
    file("phenotypes.txt"),
    file("covariates.txt"),
    file("condition_list.txt")
)
```

### Chunked Step 1
```groovy
// Split
REGENIE_STEP1_SPLIT(tuple("example", plink_files), pheno, covar, cond)

// Run chunks
Channel.of(1..10).combine(REGENIE_STEP1_SPLIT.out.chunks)
    .set { chunks_ch }
REGENIE_STEP1_RUN_CHUNK(chunks_ch)

// Merge
REGENIE_STEP1_MERGE_CHUNKS(
    REGENIE_STEP1_SPLIT.out.master,
    tuple("example", plink_files),
    REGENIE_STEP1_RUN_CHUNK.out.collect(),
    pheno, covar, cond
)
```

### Single-Variant Step 2
```groovy
REGENIE_STEP2_RUN(
    step1_predictions.collect(),
    tuple(1, "chr01", pgen, psam, pvar, null),
    "vcf",
    file("phenotypes.txt"),
    [],  // no sample file
    file("covariates.txt"),
    []   // no condition list
)
```

### Gene-Based Step 2
```groovy
REGENIE_STEP2_RUN_GENE_TESTS(
    step1_predictions,
    tuple(1, "chr01", bim, bed, fam, null),
    "pgen",
    file("phenotypes.txt"),
    file("covariates.txt"),
    [],  // no sample file
    file("annotations.txt"),
    file("setlist.txt"),
    file("masks.txt"),
    []   // no condition list
)
```

---

## Frequently Asked Questions (FAQ)

**Q: When should I use chunked Step 1?**
A: Use chunking (`params.genotypes_prediction_chunks > 0`) when:
- Limited memory (<64 GB)
- Very large prediction datasets (>1M SNPs)
- Want to parallelize Step 1 across compute nodes

**Q: What is LOCO (leave-one-chromosome-out)?**
A: REGENIE builds predictions excluding the chromosome being tested to avoid proximal contamination. One .loco.gz file per phenotype.

**Q: Why are Step 2 outputs split by chromosome?**
A: Parallelization across chromosomes enables faster execution. Results are independent per chromosome.

**Q: What's the difference between --firth and --approx?**
A: `--firth` applies exact Firth correction (slow). `--firth --approx` uses fast approximation (recommended).

**Q: How do I specify multiple phenotypes?**
A: Use comma-separated list: `--phenoColList Pheno1,Pheno2,Pheno3`. REGENIE tests all simultaneously.

**Q: What annotation format is required for gene tests?**
A: Tab-delimited file: `SNP_ID GENE_ID` (one line per SNP-gene pair).

**Q: Can I use different mask definitions for different genes?**
A: No, masks apply globally. But you can specify multiple AAF bins and test types.

**Q: What does "check-burden-files" do?**
A: Validates that annotation, setlist, and mask files are properly formatted before starting analysis.

---

## Process Files

- `regenie_step1_run.nf`: Standard Step 1 (52 lines)
- `regenie_step1_split.nf`: Chunk splitting (46 lines)
- `regenie_step1_run_chunk.nf`: Chunk execution (similar to step1_run)
- `regenie_step1_merge_chunks.nf`: Chunk merging (similar to step1_run)
- `regenie_step2_run.nf`: Single-variant tests (82 lines)
- `regenie_step2_run_gene_tests.nf`: Gene-based tests (81 lines)

---

## Related Documentation

- [REGENIE Workflows](../../../workflows/regenie/CLAUDE.md)
- [Modules Overview](../CLAUDE.md)
- [Root Documentation](../../../CLAUDE.md)
- [REGENIE Official Docs](https://rgcgithub.github.io/regenie/)
