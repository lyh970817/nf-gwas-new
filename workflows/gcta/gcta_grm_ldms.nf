/*
========================================================================================
    GCTA GRM-LDMS Workflow - LD-Stratified GRM Computation
========================================================================================

    Purpose: Calculate multiple GRMs stratified by linkage disequilibrium (LD) scores
             with centralized relatedness filtering to ensure consistent sample sizes.

    This workflow computes LD scores to segment SNPs into groups based on LD patterns,
    then calculates separate GRMs for each SNP group. To ensure consistent sample sizes
    across all GRMs (required for multi-GRM REML), relatedness filtering is performed
    centrally:
    1. Calculate GRMs for each SNP group WITHOUT relatedness filtering
    2. Combine all GRMs to create a reference combined GRM
    3. Run relatedness filtering ONCE on the combined GRM to identify unrelated individuals

    4. Apply the SAME keep file to filter ALL SNP group GRMs

    Pipeline:
    1. CALCULATE_LD_SCORES: Calculate LD scores per chromosome and segment SNPs
    2. MERGE_SNP_GROUPS: Merge SNP group files across chromosomes
    3. GCTA_GRM: Calculate GRM for each SNP group (without relatedness filtering)
    4. ADD_GRMS_GCTA: Combine all GRMs into a reference GRM
    5. REMOVE_RELATED_SUBJECTS: Filter related individuals from combined GRM
    6. FILTER_GRM_WITH_KEEP: Apply keep file to all SNP group GRMs
    7. MAKE_MGRM: Create multi-GRM file listing all filtered GRM prefixes

    Output:
    - Multiple GRMs (typically 4 groups: high LD to low LD) with consistent sample sizes
    - Multi-GRM file for use in REML-LDMS analysis
========================================================================================
*/

include { CALCULATE_LD_SCORES } from '../../modules/local/gcta/calculate_ld_scores'
include { MERGE_SNP_GROUPS } from '../../modules/local/gcta/merge_snp_groups'
include { MAKE_MGRM } from '../../modules/local/gcta/make_mgrm'
include { ADD_GRMS_GCTA } from '../../modules/local/gcta/add_grms_gcta'
include { REMOVE_RELATED_SUBJECTS } from '../../modules/local/gcta/remove_related_subjects'
include { FILTER_GRM_WITH_KEEP } from '../../modules/local/gcta/filter_grm_with_keep'
include { GCTA_GRM } from './gcta_grm'

workflow GCTA_GRM_LDMS {
  take:
  imputed_plink2_ch // Channel with imputed PLINK2 files (for GRM computation)
  imputed_plink_ch // Channel with imputed PLINK1 files (for LD score calculation)
  nparts_gcta // Number of parts for GCTA GRM calculation

  main:
  // Calculate LD scores for each chromosome and segment SNPs into groups
  CALCULATE_LD_SCORES(
    imputed_plink_ch
  )

  // Extract group number from the SNP group files
  // and group them by group number
  snp_group_ch = CALCULATE_LD_SCORES.out.snp_group_files
    .flatMap { _chr, lst ->
      // lst.withIndex() gives (Path file, int idx)
      lst
        .withIndex()
        .collect { file, idx ->
          // idx starts at 0 → add 1 so that group numbers are 1-based
          tuple(idx + 1, file)
        }
    }
    .groupTuple()

  // Merge SNP group files for each group (across chromosomes)
  MERGE_SNP_GROUPS(
    snp_group_ch
  )

  // Calculate GRM for each SNP group WITHOUT relatedness filtering
  // Relatedness filtering will be done centrally after combining all GRMs
  // Note: create_sparse_grm=false, sparse_cutoff=0.05 (not used for LDMS)
  GCTA_GRM(
    imputed_plink2_ch,
    nparts_gcta,
    MERGE_SNP_GROUPS.out.snps_to_extract,
    false,
    0.05,
    true,
  )

  // Create MGRM file for combining GRMs (before filtering)
  unfilt_grm_prefixes = GCTA_GRM.out.adjusted_grm_files
    .map { _group, prefix, _id_file, _bin_file, _n_bin_file ->
      prefix
    }
    .collect()

  // Create temp mgrm file for ADD_GRMS_GCTA
  unfilt_grm_prefixes
    .map { prefixes ->
      prefixes.join('\n')
    }
    .set { unfilt_mgrm_content }

  // Collect all unfiltered GRM files for ADD_GRMS_GCTA
  unfilt_all_grm_files = GCTA_GRM.out.adjusted_grm_files
    .flatMap { _snp_group, _prefix, grm_id, grm_bin, grm_n_bin ->
      [grm_id, grm_bin, grm_n_bin]
    }
    .collect()

  // Create mgrm file for combining
  // Note: We need to write this to a file
  MAKE_MGRM(unfilt_grm_prefixes)

  // Combine all SNP group GRMs into a single reference GRM
  ADD_GRMS_GCTA(
    MAKE_MGRM.out.mgrm_file,
    unfilt_all_grm_files,
  )

  // Run relatedness filtering ONCE on the combined GRM
  // This identifies unrelated individuals using all genetic information
  // The combined GRM is treated as snp_group "combined"
  combined_grm_for_filter = ADD_GRMS_GCTA.out.combined_grm.map { prefix, grm_id, grm_bin, grm_n_bin ->
    tuple("combined", prefix, grm_id, grm_bin, grm_n_bin)
  }

  REMOVE_RELATED_SUBJECTS(
    combined_grm_for_filter
  )

  // Apply the same keep file to ALL SNP group GRMs
  // This ensures consistent sample sizes across all GRMs
  FILTER_GRM_WITH_KEEP(
    GCTA_GRM.out.adjusted_grm_files,
    REMOVE_RELATED_SUBJECTS.out.keep_file,
  )

  // Create final MGRM file containing all filtered GRM prefixes
  filtered_grm_prefixes = FILTER_GRM_WITH_KEEP.out.filtered_grm
    .map { _group, prefix, _id_file, _bin_file, _n_bin_file ->
      prefix
    }
    .collect()

  // Create final mgrm file (need a separate process to avoid name conflict)
  filtered_grm_prefixes
    .map { prefixes ->
      prefixes.join('\n')
    }
    .collectFile(name: 'gcta_grm_ldms.mgrm', storeDir: "${params.pubDir}/gcta")
    .set { final_mgrm_file }

  // Collect all filtered GRM files for passing to analysis workflows
  all_grm_files = FILTER_GRM_WITH_KEEP.out.filtered_grm
    .flatMap { _snp_group, _prefix, grm_id, grm_bin, grm_n_bin ->
      [grm_id, grm_bin, grm_n_bin]
    }
    .collect()

  emit:
  ld_scores = CALCULATE_LD_SCORES.out.ld_scores
  snp_groups = MERGE_SNP_GROUPS.out.snps_to_extract
  grm_files = FILTER_GRM_WITH_KEEP.out.filtered_grm
  mgrm_file = final_mgrm_file
  all_grm_files = all_grm_files
  keep_file = REMOVE_RELATED_SUBJECTS.out.keep_file
}
