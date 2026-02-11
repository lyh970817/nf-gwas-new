# LDSC parameters relevant to this pipeline

This file maps `nextflow_schema.json` parameters to the corresponding program behavior/CLI usage.

| Schema parameter | Program usage in pipeline |
|---|---|
| `run_h2_ldsc_h2` | Workflow toggle for LDSC heritability (`ldsc.py --h2`). |
| `run_rg_ldsc_rg` | Workflow toggle for LDSC genetic correlation (`ldsc.py --rg`). |
| `ldsc_munge_signed_sumstats` | Argument passed to `munge_sumstats.py --signed-sumstats`. |
| `ldsc_ref_ld_chr` | Prefix for reference LD scores passed to `--ref-ld-chr`. |
| `ldsc_w_ld_chr` | Prefix for regression weights passed to `--w-ld-chr`. |
| `ldsc_munge_extra_args` | Extra CLI flags appended to `munge_sumstats.py` call. |
| `ldsc_h2_extra_args` | Extra CLI flags appended to `ldsc.py --h2` call. |
| `ldsc_rg_extra_args` | Extra CLI flags appended to `ldsc.py --rg` call. |
