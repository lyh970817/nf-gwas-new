# REGENIE Workflows

[Root Directory](../../CLAUDE.md) > [workflows](../CLAUDE.md) > **regenie**

## Change Log (Changelog)

### 2025-12-12 14:21:30
- Initial documentation creation
- Documented two-step REGENIE workflow architecture

---

## Module Responsibilities

REGENIE workflows implement the two-step whole genome regression method for biobank-scale GWAS analysis:

1. **Step 1**: Build whole genome regression model using high-quality variants (array genotypes)
2. **Step 2**: Apply model to test association with all variants (imputed genotypes)

Supports:
- Single-variant association tests (additive, recessive, dominant)
- Gene-based burden and SKAT tests
- Interaction tests (GxE, GxG)
- Conditional analyses
- Binary and quantitative traits

---

## Entry and Startup

**Primary Entry**: `regenie.nf`

**Workflow Structure**:
```groovy
workflow REGENIE {
    take:
    genotyped_final_ch      // QC-filtered PLINK files for Step 1
    phenotypes_file         // Phenotype data
    covariates_file_validated  // Validated covariates
    condition_list_file     // SNPs for conditional analysis
    imputed_plink2_ch       // Imputed genotypes for Step 2
    genotypes_association_format  // File format (vcf)
    skip_predictions        // Skip Step 1 flag

    main:
    REGENIE_STEP1(...)      // Build prediction model
    REGENIE_STEP2(...)      // Association testing

    emit:
    regenie_step1_out_ch    // Prediction files
    regenie_step2_out       // Association results
}
```

Called from `workflows/single_variant_tests.nf` (currently commented in nf_gwas.nf).

---

## External Interfaces

### Input Channels

**From REGENIE_STEP1**:
- `genotyped_final_ch`: PLINK tuple `[filename, [bed, bim, fam]]`
- `phenotypes_file`: Path to phenotype file
- `covariates_file_validated`: Path to validated covariate file
- `condition_list_file`: Optional SNP list for conditioning

**From REGENIE_STEP2**:
- `regenie_step1_out_ch`: Step 1 predictions and LOCO files
- `imputed_plink2_ch`: Chromosome-specific PLINK2 files `[chr_num, filename, bed, bim, fam, range]`
- `genotypes_association_format`: Format string (currently only 'vcf' supported)
- `phenotypes_file`: Phenotype file
- `covariates_file_validated`: Covariate file
- `condition_list_file`: Conditional SNP list

### Output Channels

**Emitted**:
- `regenie_step1_out_ch`: Step 1 output files (predictions, LOCO files, logs)
- `regenie_step2_out`: Association test results per phenotype/chromosome

---

## Key Dependencies and Configuration

### Process Dependencies

**REGENIE_STEP1** uses:
- `modules/local/regenie/regenie_step1_split.nf`: Split genotypes into chunks
- `modules/local/regenie/regenie_step1_run.nf`: Run standard Step 1
- `modules/local/regenie/regenie_step1_run_chunk.nf`: Run chunked Step 1
- `modules/local/regenie/regenie_step1_merge_chunks.nf`: Merge chunk outputs

**REGENIE_STEP2** uses:
- `modules/local/regenie/regenie_step2_run.nf`: Single-variant tests
- `modules/local/regenie/regenie_step2_run_gene_tests.nf`: Gene-based tests

### Configuration Parameters

**Step 1 Parameters**:
- `params.regenie_skip_predictions`: Skip Step 1 (bool)
- `params.regenie_bsize_step1`: Block size (default: 1000)
- `params.regenie_force_step1`: Force Step 1 with >1M variants (bool)
- `params.regenie_low_mem`: Use low-memory mode (bool, default: true)
- `params.genotypes_prediction_chunks`: Number of chunks (0 = no chunking)
- `params.regenie_step1_optional`: Additional Step 1 arguments (string)

**Step 2 Parameters**:
- `params.regenie_test`: Test type (additive/recessive/dominant)
- `params.regenie_bsize_step2`: Block size (default: 400)
- `params.regenie_firth`: Use Firth correction (bool, default: true)
- `params.regenie_firth_approx`: Approximate Firth (bool, default: true)
- `params.regenie_min_mac`: Minimum minor allele count (default: 5)
- `params.regenie_min_imputation_score`: Min INFO score (default: 0)
- `params.regenie_step2_optional`: Additional Step 2 arguments (string)

**Gene-based Test Parameters**:
- `params.regenie_run_gene_based_tests`: Enable gene tests (bool)
- `params.regenie_gene_anno`: Annotation file path
- `params.regenie_gene_setlist`: Set list file path
- `params.regenie_gene_masks`: Mask definition file path
- `params.regenie_gene_aaf`: AAF thresholds (comma-separated)
- `params.regenie_gene_test`: Test types (SKAT, ACAT, etc.)
- `params.regenie_gene_build_mask`: Mask construction method (max/sum/comphet)

**Interaction Test Parameters**:
- `params.regenie_run_interaction_tests`: Enable interaction tests (bool)
- `params.regenie_interaction`: GxE covariate name
- `params.regenie_interaction_snp`: GxG SNP identifier
- `params.regenie_rare_mac`: MAC threshold for HLM method (default: 1000)

---

## Data Models

### REGENIE Step 1 Output Structure
```
regenie_step1_out_pred.list    # List of prediction files
regenie_step1_out_1.loco.gz    # LOCO file for phenotype 1
regenie_step1_out_2.loco.gz    # LOCO file for phenotype 2
...
regenie_step1_out.log          # Log file
```

**Channel Format**: `[pred_list, loco_files, log]`

### REGENIE Step 2 Output Structure
```
regenie_step2_out_chr1_PHENO.regenie.gz   # Results per chromosome/phenotype
```

**Channel Format**: `[phenotype, chromosome, result_file]`

### Gene-Based Test Output
```
regenie_step2_gene_chr1_PHENO.regenie.gz   # Gene test results
```

---

## Testing and Quality

### Module Tests
- `tests/modules/local/regenie_step1.nf.test`: Step 1 testing
- `tests/modules/local/regenie_step2.nf.test`: Single-variant Step 2
- `tests/modules/local/regenie_step2_gene_tests.nf.test`: Gene-based tests

### Test Data
- `tests/input/pipeline/example.{bed,bim,fam}`: Genotyped data
- `tests/input/pipeline/chr*.vcf.gz`: Imputed VCF files
- `tests/input/pipeline/phenotype*.txt`: Phenotype files
- `tests/input/pipeline/gene_based_tests_regenie/`: Gene test inputs

### Validation
- Input validation via `bin/RegenieValidateInput.java`
- Log parsing via `bin/RegenieLogParser.java`

---

## Frequently Asked Questions (FAQ)

**Q: When should I chunk Step 1?**
A: Set `genotypes_prediction_chunks > 0` when you have limited memory or very large prediction datasets. Each chunk processes independently.

**Q: Can I use BGEN files?**
A: No, BGEN support has been removed. Use VCF format only.

**Q: What's the difference between Firth and Firth approximation?**
A: Firth approximation is faster but slightly less accurate. Both correct for low-frequency variant bias. Use `regenie_firth_approx: false` for exact Firth.

**Q: How do I run conditional analysis?**
A: Provide `--regenie_condition_list <file>` with SNP IDs to include as covariates.

**Q: What happens if Step 1 fails?**
A: Check log file for errors. Common issues: insufficient variants (need >1000 after QC), memory limits, or invalid phenotype/covariate format.

---

## Workflow Files

- `regenie.nf`: Main REGENIE workflow orchestrator
- `regenie_step1.nf`: Step 1 workflow (handles chunking logic)
- `regenie_step2.nf`: Step 2 workflow (single-variant and gene-based)

---

## Related Documentation

- [REGENIE Modules](../../modules/local/regenie/CLAUDE.md)
- [Single Variant Tests Workflow](../single_variant_tests.nf)
- [Root Documentation](../../CLAUDE.md)
