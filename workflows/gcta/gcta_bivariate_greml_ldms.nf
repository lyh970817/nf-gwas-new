/*
========================================================================================
    GCTA Bivariate GREML-LDMS Workflow
========================================================================================
    Estimates genetic correlation between two traits using bivariate REML with multiple
    LD-stratified GRMs (GREML-LDMS approach).

    This is the partitioned heritability version of bivariate GREML, which:
    1. Stratifies SNPs into groups based on LD scores
    2. Calculates separate GRMs for each LD stratum
    3. Applies centralized relatedness filtering for consistent sample sizes
    4. Estimates genetic correlation using multi-component bivariate REML

    Inputs:
    - phenotypes_file: Phenotype file with at least two phenotype columns
    - covariates_file: Covariate file (optional)
    - imputed_plink2_ch: PLINK2 genotype files
    - imputed_plink_ch: PLINK1 genotype files (for LD score calculation)
    - nparts_gcta: Number of GRM partitions for parallelization
    - phenotype1_name: Name of first phenotype column
    - phenotype2_name: Name of second phenotype column

    Outputs:
    - bivariate_results: .hsq file with genetic correlation and variance components
    - ld_scores: LD score files per chromosome
========================================================================================
*/

include { CALCULATE_LD_SCORES } from '../../modules/local/gcta/calculate_ld_scores'
include { MERGE_SNP_GROUPS } from '../../modules/local/gcta/merge_snp_groups'
include { PREPARE_PHENOCOV_BIVARIATE } from '../../modules/local/gcta/prepare_phenocov_bivariate'
include { MAKE_MGRM } from '../../modules/local/gcta/make_mgrm'
include { ADD_GRMS_GCTA } from '../../modules/local/gcta/add_grms_gcta'
include { REMOVE_RELATED_SUBJECTS } from '../../modules/local/gcta/remove_related_subjects'
include { FILTER_GRM_WITH_KEEP } from '../../modules/local/gcta/filter_grm_with_keep'
include { RUN_BIVARIATE_REML_LDMS } from '../../modules/local/gcta/run_bivariate_reml_ldms'
include { GCTA_GRM } from './gcta_grm'

workflow GCTA_BIVARIATE_GREML_LDMS {
    take:
    phenotype_pairs_ch  // Channel: tuple(phenotype1_name, phenotype1_file, is_binary1, phenotype2_name, phenotype2_file, is_binary2)
    covariates_file     // Path to covariates file (optional)
    imputed_plink2_ch   // Channel with imputed PLINK2 files
    imputed_plink_ch    // Channel with imputed PLINK files (for LD score calculation)
    nparts_gcta         // Number of parts for GCTA GRM calculation

    main:
    // Calculate LD scores for each chromosome and segment SNPs into groups
    CALCULATE_LD_SCORES(
        imputed_plink_ch
    )

    // Extract group number from the SNP group files
    // and group them by group number
    snp_group_ch = CALCULATE_LD_SCORES.out.snp_group_files
        .flatMap { _chr, lst ->
            /* lst.withIndex() gives (Path file, int idx) */
            lst
                .withIndex()
                .collect { file, idx ->
                    /* idx starts at 0 → add 1 so that group numbers are 1-based */
                    tuple(idx + 1, file)
                }
        }
        .groupTuple()

    // Merge SNP group files for each group
    MERGE_SNP_GROUPS(
        snp_group_ch
    )

    // Calculate GRM for each SNP group WITHOUT relatedness filtering
    // Relatedness filtering will be done centrally after combining all GRMs
    GCTA_GRM(
        imputed_plink2_ch,
        nparts_gcta,
        MERGE_SNP_GROUPS.out.snps_to_extract,
        false,  // create_sparse_grm
        0.05,   // sparse_cutoff (not used)
        true    // skip_relatedness_filter - IMPORTANT: skip for centralized filtering
    )

    // Create MGRM file for combining GRMs (before filtering)
    unfilt_grm_prefixes = GCTA_GRM.out.adjusted_grm_files
        .map { _group, prefix, _id_file, _bin_file, _n_bin_file ->
            prefix
        }
        .collect()

    // Collect all unfiltered GRM files for ADD_GRMS_GCTA
    unfilt_all_grm_files = GCTA_GRM.out.adjusted_grm_files
        .flatMap { _snp_group, _prefix, grm_id, grm_bin, grm_n_bin ->
            [grm_id, grm_bin, grm_n_bin]
        }
        .collect()

    // Create mgrm file for combining
    MAKE_MGRM(unfilt_grm_prefixes)

    // Combine all SNP group GRMs into a single reference GRM
    ADD_GRMS_GCTA(
        MAKE_MGRM.out.mgrm_file,
        unfilt_all_grm_files
    )

    // Run relatedness filtering ONCE on the combined GRM
    // This identifies unrelated individuals using all genetic information
    combined_grm_for_filter = ADD_GRMS_GCTA.out.combined_grm
        .map { prefix, grm_id, grm_bin, grm_n_bin ->
            tuple("combined", prefix, grm_id, grm_bin, grm_n_bin)
        }

    REMOVE_RELATED_SUBJECTS(
        combined_grm_for_filter
    )

    // Apply the same keep file to ALL SNP group GRMs
    // This ensures consistent sample sizes across all GRMs
    FILTER_GRM_WITH_KEEP(
        GCTA_GRM.out.adjusted_grm_files,
        REMOVE_RELATED_SUBJECTS.out.keep_file
    )

    // Create final MGRM file containing all filtered GRM prefixes
    filtered_grm_prefixes = FILTER_GRM_WITH_KEEP.out.filtered_grm
        .map { _group, prefix, _id_file, _bin_file, _n_bin_file ->
            prefix
        }
        .collect()

    // Create final mgrm file
    filtered_grm_prefixes
        .map { prefixes ->
            prefixes.join('\n')
        }
        .collectFile(name: 'gcta_grm_bivar_ldms.mgrm', storeDir: "${params.pubDir}/gcta")
        .set { final_mgrm_file }

    // Collect all filtered GRM files for multi-GRM REML
    ch_all_grm_files = FILTER_GRM_WITH_KEEP.out.filtered_grm
        .flatMap { _snp_group, _prefix, grm_id, grm_bin, grm_n_bin ->
            [grm_id, grm_bin, grm_n_bin]
        }
        .collect()

    // Prepare phenotypes for bivariate analysis
    PREPARE_PHENOCOV_BIVARIATE(
        phenotype_pairs_ch.map { phenotype1_name, phenotype1_file, _is_binary1, phenotype2_name, phenotype2_file, _is_binary2 ->
            def pair_name = "${phenotype1_name}__${phenotype2_name}"
            tuple(phenotype1_file, phenotype2_file, covariates_file, phenotype1_name, phenotype2_name, pair_name)
        }
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV_BIVARIATE.out.covariates_quant_noheader
        .collect()
        .map { files -> files ? files[0] : [] }
    def cat_covariates = PREPARE_PHENOCOV_BIVARIATE.out.covariates_cat_noheader
        .collect()
        .map { files -> files ? files[0] : [] }

    // Run bivariate REML analysis with multiple GRMs
    RUN_BIVARIATE_REML_LDMS(
        final_mgrm_file,
        ch_all_grm_files,
        PREPARE_PHENOCOV_BIVARIATE.out.phenotypes_file,
        quant_covariates,
        cat_covariates,
    )

    emit:
    ld_scores = CALCULATE_LD_SCORES.out.ld_scores
    bivariate_results = RUN_BIVARIATE_REML_LDMS.out.bivariate_results
}
