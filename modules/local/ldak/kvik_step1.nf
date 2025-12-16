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
    tuple val(genotype_name), path(bed), path(bim), path(fam)
    path phenotype_file
    path covariates_file    // Optional: [] if not provided
    val phenotype_name      // For output naming
    val is_binary           // Whether phenotype is binary (case-control)
    val mpheno              // Which phenotype column (1, 2, ... or "ALL")
    path extract_file       // Optional: SNP list to restrict analysis ([] if not provided)

    output:
    path "kvik.step1.*", emit: step1_outputs
    path "kvik.step1.root", emit: step1_root
    path "kvik.step1.loco.details", emit: step1_loco_details
    path "kvik.step1.loco.prs", emit: step1_loco_prs
    path "kvik.step1.effects", emit: step1_effects

    script:
    // Handle optional files
    def covar_param = covariates_file ? "--covar ${covariates_file}" : ''
    def binary_param = is_binary ? "--binary YES" : ''
    def mpheno_param = mpheno ? "--mpheno ${mpheno}" : ''
    def extract_param = extract_file ? "--extract ${extract_file}" : ''
    def bfile_base = bed.baseName.replace('.bed', '')

    """
    # LDAK-KVIK Step 1: Compute LOCO PRS using Elastic Net
    # Input: Directly genotyped or thinned SNPs (~500k recommended)
    # Output: LOCO PRS for each chromosome, used as offset in Step 2

    ldak6 --kvik-step1 kvik \\
        --bfile ${bfile_base} \\
        --pheno ${phenotype_file} \\
        ${covar_param} \\
        ${binary_param} \\
        ${mpheno_param} \\
        ${extract_param} \\
        --max-threads ${task.cpus}
    """
}
