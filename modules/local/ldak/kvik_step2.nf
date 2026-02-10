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
    tuple val(chr_num), val(filename), path(bed), path(bim), path(fam), path(phenotype_file), path(step1_root), path(step1_loco_details), path(step1_loco_prs), path(step1_effects), val(phenotype_name), val(mpheno), path(keep_file)
    path quant_covariates_file
    path cat_covariates_file

    output:
    tuple val(phenotype_name), val(chr_num), path("*.step2.chr${chr_num}.*"), emit: step2_chr_results
    tuple val(phenotype_name), path("*.step2.chr${chr_num}.assoc"), emit: step2_assoc
    tuple val(phenotype_name), path("*.step2.chr${chr_num}.summaries"), emit: step2_summaries, optional: true
    tuple val(phenotype_name), path("*.step2.chr${chr_num}.pvalues"), emit: step2_pvalues, optional: true

    script:
    // Handle optional files
    def covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def factors_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''
    def mpheno_param = mpheno ? "--mpheno ${mpheno}" : ''
    def keep_param = keep_file ? "--keep ${keep_file}" : ''
    def step2_optional_param = params.kvik_step2_optional ? params.kvik_step2_optional.trim() : ""
    def bfile_base = bed.baseName.replace('.bed', '')
    def step2_prefix = step1_root.name.replaceAll(/\.step1\.root$/, '')

    """
    # LDAK-KVIK Step 2: Single-SNP association analysis
    # Input: Full imputed data (this chromosome)
    # Uses: LOCO PRS from Step 1 as offset
    # Output: Association statistics for each SNP

    # Note: kvik identifier must match Step 1
    # Using --by-chr NO to prevent LDAK from automatically appending chromosome suffix
    # (we handle the naming ourselves for consistent output)
    ldak6 --kvik-step2 ${step2_prefix} \\
        --bfile ${bfile_base} \\
        --pheno ${phenotype_file} \\
        ${covar_param} \\
        ${factors_param} \\
        ${mpheno_param} \\
        ${keep_param} \\
        ${step2_optional_param} \\
        --chr ${chr_num} \\
        --by-chr NO \\
        --max-threads ${task.cpus}

    # Rename output with chromosome suffix for merging
    for f in ${step2_prefix}.step2.*; do
        if [ -f "\$f" ]; then
            ext="\${f#${step2_prefix}.step2.}"
            mv "\$f" "${step2_prefix}.step2.chr${chr_num}.\${ext}"
        fi
    done
    """
}
