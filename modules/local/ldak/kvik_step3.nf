/*
========================================================================================
    LDAK-KVIK Step 3: Gene-Based Association Analysis
========================================================================================

    Purpose: Conduct gene-based association testing via LDAK-GBAT

    This step performs:
    - LDAK-GBAT gene-based association testing
    - Uses single-SNP summary statistics from Step 2
    - Tests each gene for association with the phenotype

    Requirements:
    - Gene annotation file (RefSeq format)
    - Step 2 summaries must be merged/available
    - Step 1 outputs must be present

    Documentation: docs/external/ldak-kvik/steps.md
========================================================================================
*/

process KVIK_STEP3 {
    tag "kvik_step3_${phenotype_name}"
    publishDir "${params.pubDir}/ldak/kvik", mode: 'copy'

    label 'process_high'

    input:
    // PLINK files (full genome, merged)
    tuple val(genotype_name), path(bed), path(bim), path(fam)
    // Gene annotation file
    path genefile
    // Step 1 outputs (required for identifier matching)
    path step1_root             // kvik.step1.root
    path step1_loco_details     // kvik.step1.loco.details
    path step1_loco_prs         // kvik.step1.loco.prs
    path step1_effects          // kvik.step1.effects
    // Step 2 merged summaries (required)
    path step2_summaries        // Merged kvik.step2.summaries
    val phenotype_name          // For output naming

    output:
    path "kvik.step3.*", emit: step3_outputs
    path "kvik.step3.remls.all", emit: step3_remls_all, optional: true

    script:
    def bfile_base = bed.baseName.replace('.bed', '')

    """
    # LDAK-KVIK Step 3: Gene-based association analysis
    # Uses: LDAK-GBAT methodology
    # Input: Gene annotation file + Step 2 summaries
    # Output: Gene-level association statistics

    ldak6 --kvik-step3 kvik \\
        --bfile ${bfile_base} \\
        --genefile ${genefile} \\
        --max-threads ${task.cpus}
    """
}
