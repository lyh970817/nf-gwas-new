#!/usr/bin/env nextflow
/*
========================================================================================
    genepi/nf-gwas
========================================================================================
    Github : https://github.com/genepi/nf-gwas
    Author: Sebastian Schönherr & Lukas Forer
    ---------------------------
*/



include { paramsSummaryLog } from 'plugin/nf-schema'




include { NF_GWAS } from './workflows/nf_gwas'

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

workflow {

// if (params.help) {
//    def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
//    def String command = "nextflow run ${workflow.manifest.name} --config test.conf"
//    log.info paramsHelp(command) + citation
//    exit 0
// }

// Validate input parameters
// if (params.validate_params) {
//     validateParameters()
// }

// Print summary of supplied parameters
log.info paramsSummaryLog(workflow)
    NF_GWAS ()

workflow.onComplete = {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
}
