/*
========================================================================================
    LDAK-KVIK Step 1: LOCO PRS Computation
========================================================================================

    Purpose: Compute Leave-One-Chromosome-Out (LOCO) polygenic risk scores using Elastic Net

    This step performs:
    1. Test for population structure
    2. Estimate power and heritability parameters
    3. Refine heritability via Monte Carlo REML
    4. Elastic Net cross-validation
    5. LOCO PRS construction

    Recommendations:
    - Use directly genotyped SNPs or a thinned subset (~500k SNPs) for speed
    - For binary traits, add --binary YES

    Documentation: docs/external/ldak-kvik/steps.md
========================================================================================
*/

process KVIK_STEP1 {
    tag "kvik_step1_${phenotype_name}"
    publishDir "${params.pubDir}/ldak/kvik", mode: 'copy'

    label 'process_high'

    input:
    // PLINK files for Step 1 (directly genotyped or thinned subset)
    tuple val(genotype_name), path(bed), path(bim), path(fam), path(phenotype_file), val(phenotype_name), val(is_binary), val(mpheno)
    path quant_covariates_file
    path cat_covariates_file

    output:
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step1.*" }, emit: step1_outputs
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step1.root" }, emit: step1_root
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step1.loco.details" }, emit: step1_loco_details
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step1.loco.prs" }, emit: step1_loco_prs
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step1.effects" }, emit: step1_effects

    script:
    // Handle optional files
    def covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def factors_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''
    def binary_param = is_binary ? "--binary YES" : ''
    def mpheno_param = mpheno ? "--mpheno ${mpheno}" : ''
    def step1_optional_param = params.kvik_step1_optional ? params.kvik_step1_optional.trim() : ""
    def bfile_base = bed.baseName.replace('.bed', '')
    def phenotype_slug = phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')

    """
    # LDAK-KVIK Step 1: Compute LOCO PRS using Elastic Net
    # Input: Directly genotyped or thinned SNPs (~500k recommended)
    # Output: LOCO PRS for each chromosome, used as offset in Step 2

    ldak6 --kvik-step1 kvik_${phenotype_slug} \\
        --bfile ${bfile_base} \\
        --pheno ${phenotype_file} \\
        ${covar_param} \\
        ${factors_param} \\
        ${binary_param} \\
        ${mpheno_param} \\
        ${step1_optional_param} \\
        --max-threads ${task.cpus}

    """
}
