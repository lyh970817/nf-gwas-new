/*
========================================================================================
    LDAK-KVIK Step 2: Single-SNP Association Analysis
========================================================================================

    Purpose: Perform single-SNP association analysis using LOCO PRS as offset

    This step performs:
    1. Calculate uncalibrated test statistics
    2. Scale test statistics using lambda from Step 1
    3. Apply saddlepoint approximation for binary traits (optional)

    Requirements:
    - The kvik-step2 identifier must match Step 1 identifier
    - Step 1 outputs must be present in working directory
    - Can process each chromosome separately for parallelization

    Documentation: docs/external/ldak-kvik/steps.md
========================================================================================
*/

process KVIK_STEP2 {
    tag "kvik_step2_chr${chr_num}"
    publishDir "${params.pubDir}/ldak/kvik", mode: 'copy'

    label 'process_medium'

    input:
    // PLINK files for Step 2 (full imputed data, per-chromosome)
    tuple val(chr_num), val(filename), path(bed), path(bim), path(fam)
    path phenotype_file
    path covariates_file        // Optional: [] if not provided
    // Step 1 outputs (required)
    path step1_root             // kvik.step1.root
    path step1_loco_details     // kvik.step1.loco.details
    path step1_loco_prs         // kvik.step1.loco.prs
    path step1_effects          // kvik.step1.effects
    val mpheno                  // Which phenotype column (1, 2, ... or "ALL")
    path keep_file              // Optional: sample list to restrict analysis ([] if not provided)

    output:
    tuple val(chr_num), path("kvik.step2.chr${chr_num}.*"), emit: step2_chr_results
    path "kvik.step2.chr${chr_num}.assoc", emit: step2_assoc
    path "kvik.step2.chr${chr_num}.summaries", emit: step2_summaries, optional: true
    path "kvik.step2.chr${chr_num}.pvalues", emit: step2_pvalues, optional: true

    script:
    // Handle optional files
    def covar_param = covariates_file ? "--covar ${covariates_file}" : ''
    def mpheno_param = mpheno ? "--mpheno ${mpheno}" : ''
    def keep_param = keep_file ? "--keep ${keep_file}" : ''
    def bfile_base = bed.baseName.replace('.bed', '')

    """
    # LDAK-KVIK Step 2: Single-SNP association analysis
    # Input: Full imputed data (this chromosome)
    # Uses: LOCO PRS from Step 1 as offset
    # Output: Association statistics for each SNP

    # Note: kvik identifier must match Step 1
    # Using --by-chr NO to prevent LDAK from automatically appending chromosome suffix
    # (we handle the naming ourselves for consistent output)
    ldak6 --kvik-step2 kvik \\
        --bfile ${bfile_base} \\
        --pheno ${phenotype_file} \\
        ${covar_param} \\
        ${mpheno_param} \\
        ${keep_param} \\
        --chr ${chr_num} \\
        --by-chr NO \\
        --max-threads ${task.cpus}

    # Rename output with chromosome suffix for merging
    for f in kvik.step2.*; do
        if [ -f "\$f" ]; then
            ext="\${f#kvik.step2.}"
            mv "\$f" "kvik.step2.chr${chr_num}.\${ext}"
        fi
    done
    """
}
