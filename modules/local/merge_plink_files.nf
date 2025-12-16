/*
========================================================================================
    Merge PLINK Files: Combine Per-Chromosome PLINK Files
========================================================================================

    Purpose: Merge per-chromosome PLINK1 files into a single genome-wide file

    Used for:
    - Creating merged genotype files for LDAK-KVIK Step 1
    - Any analysis requiring whole-genome PLINK files

    Documentation: docs/external/ldak-kvik/ukbrap/preparation.md
========================================================================================
*/

process MERGE_PLINK_FILES {
    tag "merge_plink"
    publishDir "${params.pubDir}/merged_plink", mode: 'copy'

    label 'process_medium'

    input:
    // Collected PLINK files from all chromosomes
    // Each entry: [chr_num, filename, bed, bim, fam, range]
    path bed_files
    path bim_files
    path fam_files
    val output_prefix

    output:
    tuple val(output_prefix), path("${output_prefix}.bed"), path("${output_prefix}.bim"), path("${output_prefix}.fam"), emit: merged_plink

    script:
    """
    # Create list of files to merge (PLINK format: one prefix per line)
    for bed in *.bed; do
        basename="\${bed%.bed}"
        echo "\$basename" >> files_to_merge.txt
    done

    # Merge all chromosome files using PLINK
    plink --merge-list files_to_merge.txt \\
        --make-bed \\
        --out ${output_prefix} \\
        --threads ${task.cpus}
    """
}
