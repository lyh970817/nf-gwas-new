include { REGENIE_STEP1_RUN           } from '../../modules/local/regenie/regenie_step1_run'
include { REGENIE_STEP1_SPLIT         } from '../../modules/local/regenie/regenie_step1_split'
include { REGENIE_STEP1_MERGE_CHUNKS  } from '../../modules/local/regenie/regenie_step1_merge_chunks'
include { REGENIE_STEP1_RUN_CHUNK     } from '../../modules/local/regenie/regenie_step1_run_chunk'

workflow REGENIE_STEP1 {

    take:
    genotyped_final_ch
    phenotypes_file
    covariates_file_validated
    condition_list_file

    main:
    if (params.genotypes_prediction_chunks > 0){

        REGENIE_STEP1_SPLIT (
        genotyped_final_ch,
        phenotypes_file,
        covariates_file_validated,
        condition_list_file
        )

        Channel.of(1..params.genotypes_prediction_chunks)
            .combine(REGENIE_STEP1_SPLIT.out.chunks)
            .set { chunks_ch }

        REGENIE_STEP1_RUN_CHUNK (
            chunks_ch
        )

        REGENIE_STEP1_MERGE_CHUNKS (
            REGENIE_STEP1_SPLIT.out.master.collect(),
            genotyped_final_ch.collect(),
            REGENIE_STEP1_RUN_CHUNK.out.regenie_step1_out.collect(),
            phenotypes_file,
            covariates_file_validated,
            condition_list_file
        )

        // merge pred.list files from chunks and add it to output channel
        mergedPredList = REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out_pred.collectFile()
        regenie_step1_out_ch = REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out.concat(mergedPredList)

    } else {
        REGENIE_STEP1_RUN (
            genotyped_final_ch,
            phenotypes_file,
            covariates_file_validated,
            condition_list_file
        )

        regenie_step1_out_ch = REGENIE_STEP1_RUN.out.regenie_step1_out
    }
    emit:
    regenie_step1_out_ch
}

