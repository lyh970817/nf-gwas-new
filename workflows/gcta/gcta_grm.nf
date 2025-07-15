// Import processes
include { MAKE_MPFILES } from '../../modules/local/gcta/make_mpfiles'
include { MERGE_MPFILES } from '../../modules/local/gcta/merge_mpfiles'
include { MAKE_GRM_PART } from '../../modules/local/gcta/make_grm_part'
include { MERGE_GRM_PARTS } from '../../modules/local/gcta/merge_grm_parts'
include { ADJUST_GRM } from '../../modules/local/gcta/adjust_grm'
include { REMOVE_RELATED_SUBJECTS } from '../../modules/local/gcta/remove_related_subjects'
include { MAKE_MGRM } from '../../modules/local/gcta/make_mgrm'

// Function to create a channel with part numbers based on nparts_gcta
def create_part_channel(nparts_gcta) {
    return Channel.of(1..nparts_gcta)
}

// Main workflow for GCTA GRM calculation
workflow GCTA_GRM {
    take:
    imputed_plink2_ch  // Channel with imputed PLINK2 files
    nparts_gcta        // Number of parts for GCTA GRM calculation
    snps_to_extract_ch    // Optional channel with SNPs to extract (default: empty channel)j

    main:
    // Create mpfiles for each chromosome
    MAKE_MPFILES(imputed_plink2_ch)

    // Merge all chromosome mpfiles
    MERGE_MPFILES(MAKE_MPFILES.out.mpfile_part.collect())

    // Create a channel with part numbers
    part_channel = create_part_channel(nparts_gcta)

    // Combine part_channel with nparts_gcta
    parts_with_nparts = part_channel.combine(Channel.value(nparts_gcta))
    parts_with_nparts
        .combine(snps_to_extract_ch).view()
        .set{ parts_and_snps_ch }

    // Collect all PLINK2 files for use in MAKE_GRM_PART
    plink2_files = imputed_plink2_ch
        .map { _chr_num, _filename, pgen, psam, pvar, _range ->
            [pgen, psam, pvar]
        }
        .flatten()
        .collect()

    // Run GCTA GRM calculation for each part
    MAKE_GRM_PART(
        MERGE_MPFILES.out.mpfile,
        parts_and_snps_ch,
        plink2_files
    )

    MAKE_GRM_PART.out.grm_files
        .groupTuple(by : [0,1])
        .set{ grm_files_by_nparts_and_snp_group }

    // Merge all GRM parts
    MERGE_GRM_PARTS(
        grm_files_by_nparts_and_snp_group
    )

    // // Adjust GRM for incomplete tagging of causal SNPs
    ADJUST_GRM(
        MERGE_GRM_PARTS.out.grm_files
    )

    // // Remove related subjects using grm-cutoff 0.05
    // // NOTE: This step forbids per chromosome operation
    REMOVE_RELATED_SUBJECTS(
        ADJUST_GRM.out.grm_files
    )

    emit:

    // Unrelated subjects GRM as tuple
    grm_files = REMOVE_RELATED_SUBJECTS.out.grm_files
}
