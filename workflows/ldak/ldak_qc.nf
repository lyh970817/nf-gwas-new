/*
========================================================================================
    LDAK QC Workflow - Test for inflation due to structure and relatedness
========================================================================================
*/

include { CALC_KINS } from './calc_kins'
include { MAKE_MGRM_LDAK } from '../../modules/local/ldak/make_mgrm_ldak'
include { ADD_GRMS } from '../../modules/local/ldak/add_grms'
include { LDAK_REML } from '../../modules/local/ldak/ldak_reml'
include { LDAK } from './ldak'
include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { CALC_INFLATION } from '../../modules/local/ldak/calc_inflation'
include { CALC_GENOTYPE_ERROR } from '../../modules/local/ldak/calc_genotype_error'

workflow LDAK_QC {
    take:
    imputed_plink_ch   // Channel with imputed PLINK files (bed, bim, fam)
    phenotype_file     // Path to phenotype file
    covariates_file    // Path to covariates file (optional)

    main:
    // Group chromosomes by quarters based on total number of chromosomes
    chromosome_quarters = imputed_plink_ch
        .map { chr_num, filename, bed, bim, fam, range ->
            // Keep the range information in the tuple
            [chr_num, filename, bed, bim, fam, range]
        }
        .toList()
        .map { chr_list ->
            def total_chrs = chr_list.size()
            def quarters = []

            if (total_chrs >= 4) {
                // Divide into 4 quarters
                def quarter_size = Math.ceil(total_chrs / 4.0) as Integer
                quarters = (0..<4).findAll { i ->
                    def start = i * quarter_size
                    start < total_chrs
                }.collect { i ->
                    def start = i * quarter_size
                    def end = Math.min(start + quarter_size, total_chrs)
                    ["quarter${i+1}", chr_list[start..<end]]
                }
            } else if (total_chrs == 3) {
                // Divide into 3 parts
                quarters = [
                    ["quarter1", [chr_list[0]]],
                    ["quarter2", [chr_list[1]]],
                    ["quarter3", [chr_list[2]]]
                ]
            } else if (total_chrs == 2) {
                // Divide into 2 parts
                quarters = [
                    ["quarter1", [chr_list[0]]],
                    ["quarter2", [chr_list[1]]]
                ]
            } else {
                // Single chromosome - no division
                quarters = [["quarter1", chr_list]]
            }

            return quarters
        }
        .flatMap { quarters_list ->
            quarters_list.collectMany { quarter_name, chr_data_list ->
                chr_data_list.collect { chr_num, filename, bed, bim, fam, range ->
                    [quarter_name + "_chr" + chr_num, filename, bed, bim, fam, range]
                }
            }
        }

    // Calculate kinship matrices for each chromosome
    CALC_KINS(chromosome_quarters, "human_default")

    // Prepare phenotypes and covariates files
    PREPARE_PHENOCOV(
        phenotype_file,
        covariates_file
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .ifEmpty { Channel.of([]) }

    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .ifEmpty { Channel.of([]) }

    // Group GRMs by quarter
    quarter_grms = CALC_KINS.out.ldak_grm
        .map { chr_num, filename, bin, id, details, adjust ->
            def quarter = chr_num.split('_chr')[0]
            [quarter, chr_num, filename, bin, id, details, adjust]
        }
        .groupTuple()

    // Handle single chromosome quarters (direct GRM)
    single_chr_quarters = quarter_grms
        .filter { _quarter, _chr_nums, filenames, _bins, _ids, _details_list, _adjusts -> filenames.size() == 1 }
        .map { quarter, _chr_nums, filenames, bins, ids, details_list, adjusts ->
            [quarter, filenames[0], bins[0], ids[0], details_list[0], adjusts[0]]
        }

    // Handle multi-chromosome quarters (need to combine GRMs)
    multi_chr_quarters = quarter_grms
        .filter { _quarter, _chr_nums, filenames, _bins, _ids, _details_list, _adjusts -> filenames.size() > 1 }

    // Create MGRM files for multi-chromosome quarters
    multi_quarter_mgrm = multi_chr_quarters
        .map { quarter, _chr_nums, filenames, _bins, _ids, _details_list, _adjusts ->
            [quarter, filenames]
        }

    MAKE_MGRM_LDAK(multi_quarter_mgrm.map { it[1] }, multi_quarter_mgrm.map { it[0] })

    // Combine GRMs for multi-chromosome quarters
    multi_quarter_grm_files = multi_chr_quarters
        .map { quarter, _chr_nums, _filenames, bins, ids, details_list, adjusts ->
            [quarter, [bins, ids, details_list, adjusts].transpose().flatten()]
        }
        .combine(MAKE_MGRM_LDAK.out.mgrm_file)
        .map { quarter_data, mgrm_file ->
            [quarter_data[0], mgrm_file, quarter_data[1]]
        }

    ADD_GRMS(
        multi_quarter_grm_files.map { it[1] },
        multi_quarter_grm_files.map { it[2] },
        multi_quarter_grm_files.map { it[0] }
    )

    // Combine single and multi chromosome quarter results
    combined_quarters = single_chr_quarters
        .mix(
            multi_quarter_grm_files.map { it[0] }
                .combine(ADD_GRMS.out.combined_grm)
                .map { quarter, combined_grm ->
                    [quarter, combined_grm[0], combined_grm[1], combined_grm[2], combined_grm[3], combined_grm[4]]
                }
        )

    LDAK(
        imputed_plink_ch,
        phenotype_file,
        covariates_file,
        "human_default"
    )

    // Run REML analysis for each quarter
    quarter_reml_input = combined_quarters
        .map { _quarter, filename, bin, id, details, adjust ->
            [filename, bin, id, details, adjust]
        }
        .combine(LDAK.out.filtered_list)
        .combine(PREPARE_PHENOCOV.out.phenotypes_noheader)
        .combine(quant_covariates)
        .combine(cat_covariates)


    LDAK_REML(
        quarter_reml_input.map { it[0] },
        quarter_reml_input.map { it[1] },
        quarter_reml_input.map { it[2] },
        quarter_reml_input.map { it[3] },
        quarter_reml_input.map { it[4] }
    )
    

    // Calculate inflation using quarter REML results and LDAK REML results
    CALC_INFLATION(
        LDAK.out.reml_results,
        LDAK_REML.out.reml_results.collect()
    )

    // Calculate genotype error if batch subset parameters are provided
    if (params.batch_subset_prefix && params.batch_subset_number) {
        // Create batch subset tuple
        batch_subsets = [params.batch_subset_prefix, params.batch_subset_number, (1..params.batch_subset_number).collect { "${params.batch_subset_prefix}${it}" }]

        CALC_GENOTYPE_ERROR(
            imputed_plink_ch,
            phenotype_file,
            covariates_file,
            batch_subsets
        )
    }

    emit:
    quarter_reml_results = LDAK_REML.out.reml_results
    inflation_results = CALC_INFLATION.out.inflation_results
    genotype_error_results = (params.batch_subset_prefix && params.batch_subset_number) ? CALC_GENOTYPE_ERROR.out.he_results : Channel.empty()
    // quarter_info = quarter_grms
}