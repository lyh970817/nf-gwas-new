/*
========================================================================================
    GCTA GRM Workflow - Genetic Relationship Matrix Computation
========================================================================================

    Purpose: Calculate genetic relationship matrix (GRM) with optional sparse output

    Pipeline:
    1. MAKE_MPFILES: Create mpfiles for each chromosome
    2. MERGE_MPFILES: Merge chromosome mpfiles
    3. MAKE_GRM_PART: Calculate GRM parts (parallelized)
    4. MERGE_GRM_PARTS: Merge GRM parts
    5. ADJUST_GRM: Adjust for incomplete tagging
    6. REMOVE_RELATED_SUBJECTS: Filter related individuals
    7. [Optional] MAKE_BK_SPARSE: Create sparse GRM for FastGWA

    This workflow can be used standalone for GRM-only computation,
    or as a subworkflow within GCTA_GREML/GCTA_FASTGWA.
========================================================================================
*/

// Import processes
include { MAKE_MPFILES } from '../../modules/local/gcta/make_mpfiles'
include { MERGE_MPFILES } from '../../modules/local/gcta/merge_mpfiles'
include { MAKE_GRM_PART } from '../../modules/local/gcta/make_grm_part'
include { MERGE_GRM_PARTS } from '../../modules/local/gcta/merge_grm_parts'
include { ADJUST_GRM } from '../../modules/local/gcta/adjust_grm'
include { REMOVE_RELATED_SUBJECTS } from '../../modules/local/gcta/remove_related_subjects'
include { MAKE_MGRM } from '../../modules/local/gcta/make_mgrm'
include { MAKE_BK_SPARSE } from '../../modules/local/gcta/make_bk_sparse'

// Function to create a channel with part numbers based on nparts_gcta
def create_part_channel(nparts_gcta) {
    return Channel.of(1..nparts_gcta)
}

// Main workflow for GCTA GRM calculation
workflow GCTA_GRM {
    take:
    imputed_plink2_ch     // Channel with imputed PLINK2 files
    nparts_gcta           // Number of parts for GCTA GRM calculation
    snps_to_extract_ch    // Optional channel with SNPs to extract (default: [["0", []]])
    create_sparse_grm     // Boolean: whether to create sparse GRM for FastGWA
    sparse_cutoff         // Cutoff for sparse GRM (default: 0.05)
    skip_relatedness_filter  // Boolean: skip REMOVE_RELATED_SUBJECTS (for LDMS centralized filtering)

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
        .combine(snps_to_extract_ch)
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

    // Conditionally remove related subjects
    // Skip this step for LDMS workflow (centralized filtering will be done later)
    if (skip_relatedness_filter) {
        // Output adjusted GRM without relatedness filtering
        grm_out = ADJUST_GRM.out.grm_files
        keep_file_out = Channel.empty()
    } else {
        // Remove related subjects using grm-cutoff 0.05
        REMOVE_RELATED_SUBJECTS(
            ADJUST_GRM.out.grm_files
        )
        grm_out = REMOVE_RELATED_SUBJECTS.out.grm_files
        keep_file_out = REMOVE_RELATED_SUBJECTS.out.keep_file
    }

    // Optionally create sparse GRM for FastGWA
    if (create_sparse_grm) {
        MAKE_BK_SPARSE(
            grm_out,
            sparse_cutoff
        )
        sparse_grm_out = MAKE_BK_SPARSE.out.sparse_grm_files
    } else {
        // Create empty channel if sparse GRM not requested
        sparse_grm_out = Channel.empty()
    }

    emit:
    // Dense GRM files (always emitted)
    grm_files = grm_out
    // Sparse GRM files (only if create_sparse_grm=true)
    sparse_grm_files = sparse_grm_out
    // Adjusted GRM files (before relatedness filtering)
    adjusted_grm_files = ADJUST_GRM.out.grm_files
    // Keep file (only if skip_relatedness_filter=false)
    keep_file = keep_file_out
}
