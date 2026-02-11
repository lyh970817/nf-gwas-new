# REGENIE parameters relevant to this pipeline

This file maps `nextflow_schema.json` parameters to the corresponding program behavior/CLI usage.

| Schema parameter | Program usage in pipeline |
|---|---|
| `run_assoc_regenie` | Workflow toggle for REGENIE association analysis. |
| `regenie_skip_predictions` | Uses `--ignore-pred` in step 2 and bypasses step 1 prediction files. |
| `regenie_test` | Value passed to `--test` in REGENIE step 2. |
| `regenie_force_step1` | Adds `--force-step1` in step 1 commands. |
| `regenie_low_mem` | Adds `--lowmem --lowmem-prefix` in step 1 commands. |
| `regenie_firth` | Adds `--firth` in step 2 for binary-trait correction. |
| `regenie_firth_approx` | Adds `--approx` when Firth correction is enabled. |
| `regenie_bsize_step1` | Block size passed via `--bsize` in step 1. |
| `regenie_bsize_step2` | Block size passed via `--bsize` in step 2. |
| `regenie_step1_optional` | Extra CLI flags appended to step 1 command. |
| `regenie_step2_optional` | Extra CLI flags appended to step 2 command. |
