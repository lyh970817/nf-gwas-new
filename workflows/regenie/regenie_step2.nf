include { REGENIE_STEP2_RUN        } from '../../modules/local/regenie/regenie_step2_run'
include { MERGE_REGENIE_RESULTS   } from '../../modules/local/regenie/merge_regenie_results'
include { MUNGE_SUMSTATS          } from '../../modules/local/regenie/munge_sumstats'

workflow REGENIE_STEP2 {

    take:
    regenie_step1_out_ch
    imputed_plink1_ch
    genotypes_association_format
    phenotypes_file
    covariates_file_validated
    condition_list_file

    main:
    if (!params.regenie_sample_file) {
        sample_file = []
    } else {
        sample_file = file(params.regenie_sample_file, checkIfExists: true)
    }

    REGENIE_STEP2_RUN (
        regenie_step1_out_ch.collect(),
        imputed_plink1_ch,
        genotypes_association_format,
        phenotypes_file,
        sample_file,
        covariates_file_validated,
        condition_list_file
    )

    regenie_step2_out = REGENIE_STEP2_RUN.out.regenie_step2_out

    // Group results by phenotype and merge across chromosomes
    // Without --no-split, REGENIE creates separate files per phenotype: output_PHENO.regenie.gz
    // Extract phenotype from filename pattern: *_PHENOTYPE.regenie.gz
    regenie_step2_out
        .flatMap { filename, regenie_files ->
            // Handle both single file and list of files
            def files = regenie_files instanceof List ? regenie_files : [regenie_files]
            files.collect { f ->
                // Extract phenotype: filename pattern is like "chr01.vcf-1_Y1.regenie.gz"
                def phenotype = f.name.replaceAll(/.*_(.+)\.regenie\.gz/, '$1')
                [phenotype, f]
            }
        }
        .groupTuple()
        .set { grouped_by_phenotype_ch }

    MERGE_REGENIE_RESULTS(grouped_by_phenotype_ch)

    merged_results = MERGE_REGENIE_RESULTS.out.merged_results

    // Optionally run MungeSumstats to standardize summary statistics
    munged_sumstats = Channel.empty()
    if (params.run_munge_sumstats) {
        def genome_build = params.munge_genome_build ?: 'GRCh38'
        MUNGE_SUMSTATS(merged_results, genome_build)
        munged_sumstats = MUNGE_SUMSTATS.out.munged_sumstats
    }

    emit:
    regenie_step2_out
    merged_results
    munged_sumstats

}