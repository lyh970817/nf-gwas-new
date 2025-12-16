/*
========================================================================================
    LCV Causal Inference Workflow
========================================================================================
    Workflow for running LCV (Latent Causal Variable) analysis to infer genetically
    causal relationships between two traits using GWAS summary statistics.

    LCV estimates the genetic causal proportion (GCP), which ranges from -1 to 1:
    - |GCP| = 1: Full genetic causality (one trait causes the other)
    - GCP = 0: No genetic causality (correlation is due to shared factors)
    - GCP > 0: Trait 1 is partially causal for Trait 2
    - GCP < 0: Trait 2 is partially causal for Trait 1

    Reference: O'Connor & Price (2018) Nature Genetics.
========================================================================================
*/

include { LCV_RUN_ANALYSIS } from '../../modules/local/lcv/lcv_run_analysis'

workflow LCV_CAUSAL {

    take:
    analysis_id              // Unique analysis identifier
    sumstats_file1           // Summary statistics for trait 1 (must have SNP, Z columns)
    sumstats_file2           // Summary statistics for trait 2 (must have SNP, Z columns)
    ldscores_file            // LD scores file (must have SNP, L2 columns)
    trait1_name              // Name of trait 1
    trait2_name              // Name of trait 2
    no_blocks                // Number of jackknife blocks (default: 100)
    sig_threshold            // Significance threshold (default: 30)
    crosstrait_intercept     // Estimate cross-trait intercept (0 or 1)
    ldsc_intercept           // Estimate LDSC intercept (0 or 1)

    main:

    // Run LCV analysis
    LCV_RUN_ANALYSIS(
        analysis_id,
        sumstats_file1,
        sumstats_file2,
        ldscores_file,
        trait1_name,
        trait2_name,
        no_blocks,
        sig_threshold,
        crosstrait_intercept,
        ldsc_intercept
    )

    emit:
    results  = LCV_RUN_ANALYSIS.out.results
    log_file = LCV_RUN_ANALYSIS.out.log_file
}
