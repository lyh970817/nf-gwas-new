# LCV parameters relevant to this pipeline

This file maps `nextflow_schema.json` parameters to the corresponding program behavior/CLI usage.

| Schema parameter | Program usage in pipeline |
|---|---|
| `run_lcv_causal` | Workflow toggle for LCV causal inference analysis. |
| `lcv_analysis_id` | Output prefix used for LCV result/log files. |
| `lcv_ldscores_file` | LD-score file consumed by the LCV R implementation. |
| `lcv_sumstats_trait1` | Summary statistics file for trait 1. |
| `lcv_sumstats_trait2` | Summary statistics file for trait 2. |
| `lcv_trait1_name` | Trait 1 display/name label in LCV outputs. |
| `lcv_trait2_name` | Trait 2 display/name label in LCV outputs. |
| `lcv_no_blocks` | Number of jackknife blocks used by LCV resampling. |
| `lcv_sig_threshold` | Significance threshold used by the LCV module. |
| `lcv_crosstrait_intercept` | Cross-trait intercept setting fed into LCV estimator. |
| `lcv_ldsc_intercept` | Single-trait LDSC intercept setting fed into LCV estimator. |
