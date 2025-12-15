/*
========================================================================================
    LDAK GRM Workflow - Kinship Matrix Computation
========================================================================================

    Purpose: Calculate LDAK kinship matrix (GRM equivalent) for heritability estimation

    This workflow computes chromosome-level kinships, combines them, and filters related
    individuals. GRM adjustment for HE/PCGC is handled in their respective analysis workflows.

    Pipeline:
    1. CALC_KINS: Calculate per-chromosome kinships (model-dependent)
    2. MAKE_MGRM_LDAK: Create multi-GRM file listing kinship prefixes
    3. ADD_GRMS: Combine chromosome kinships into genome-wide GRM
    4. FILTER_RELATEDNESS: Remove related individuals AND create filtered GRM

    Kinship Models:
    - human_default: LDAK model with power -.25 (recommended for human data)
    - uniform: Equal weighting across SNPs
    - ldak-thin: LD-based thinning approach

    This workflow can be used standalone for kinship-only computation,
    or as a subworkflow within LDAK_REML/HE/PCGC.

    Output GRMs:
    - combined_grm: Full GRM (all individuals, before relatedness filtering)
    - filtered_grm: GRM with related individuals removed (5-tuple, ready for REML or adjustment)

    Note: For HE and PCGC regression, the filtered_grm should be passed to
    LDAK_HE_ANALYSIS or LDAK_PCGC_ANALYSIS, which handle adjustment internally.
========================================================================================
*/

include { CALC_KINS } from './calc_kins'
include { MAKE_MGRM_LDAK } from '../../modules/local/ldak/make_mgrm_ldak'
include { ADD_GRMS } from '../../modules/local/ldak/add_grms'
include { FILTER_RELATEDNESS } from '../../modules/local/ldak/filter_relatedness'

workflow LDAK_GRM {
    take:
    imputed_plink_ch     // Channel with imputed PLINK files (bed, bim, fam)
    heritability_model   // Heritability model: human_default, uniform, or ldak-thin

    main:
    // Calculate kinship matrices per chromosome
    CALC_KINS(
        imputed_plink_ch,
        heritability_model
    )

    // Extract GRM prefixes from CALC_KINS output
    grm_prefixes = CALC_KINS.out.ldak_grm
        .map { _chr_num, filename, _bin_file, _id_file, _details_file, _adjust_file ->
            filename
        }
        .collect()

    // Create MGRM file containing all GRM root names
    MAKE_MGRM_LDAK(
        grm_prefixes,
        "ldak_grm"
    )

    // Collect all GRM files for use in ADD_GRMS
    grm_files = CALC_KINS.out.ldak_grm
        .map { _chr_num, _filename, bin_file, id_file, details_file, adjust_file ->
            [bin_file, id_file, details_file, adjust_file]
        }
        .flatten()
        .collect()

    // Combine all chromosome GRMs
    ADD_GRMS(
        MAKE_MGRM_LDAK.out.mgrm_file,
        grm_files,
        "ldak_grm"
    )

    // Filter related individuals from the combined GRM
    // This outputs BOTH a filtered list AND a filtered GRM (5-tuple)
    FILTER_RELATEDNESS(
        ADD_GRMS.out.combined_grm
    )

    emit:
    // Per-chromosome kinships
    ldak_grm = CALC_KINS.out.ldak_grm
    // Multi-GRM file
    mgrm_file = MAKE_MGRM_LDAK.out.mgrm_file
    // Combined genome-wide kinship (all individuals, before filtering)
    combined_grm = ADD_GRMS.out.combined_grm
    // List of unrelated individuals (keep/lose/maxrel files - for reference)
    filtered_list = FILTER_RELATEDNESS.out.filtered_list
    // Filtered GRM containing only unrelated individuals (5-tuple, ready for REML or adjustment)
    filtered_grm = FILTER_RELATEDNESS.out.filtered_grm
}
