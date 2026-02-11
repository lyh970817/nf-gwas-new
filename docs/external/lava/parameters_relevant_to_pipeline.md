# LAVA parameters relevant to this pipeline

This file maps `nextflow_schema.json` parameters to the corresponding program behavior/CLI usage.

| Schema parameter | Program usage in pipeline |
|---|---|
| `run_lava_local_rg` | Workflow toggle for LAVA local genetic correlation analysis. |
| `lava_analysis_id` | Output prefix used for all LAVA result/log files. |
| `lava_ref_plink` | Reference LD PLINK triple used by `process.input` in LAVA module. |
| `lava_loci_file` | Loci definition file passed into LAVA analysis. |
| `lava_sample_overlap_file` | Optional sample-overlap file passed into LAVA when available. |
| `lava_univ_threshold` | Univariate p-value threshold used to select loci for bivariate testing. |
