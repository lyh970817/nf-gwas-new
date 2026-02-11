# LDAK parameters relevant to this pipeline

This file maps `nextflow_schema.json` parameters to the corresponding program behavior/CLI usage.

| Schema parameter | Program usage in pipeline |
|---|---|
| `run_h2_ldak_grm` | Workflow toggle for LDAK GRM generation. |
| `run_h2_ldak_reml` | Workflow toggle for LDAK REML heritability analysis. |
| `run_h2_ldak_he` | Workflow toggle for LDAK Haseman-Elston regression. |
| `run_h2_ldak_pcgc` | Workflow toggle for LDAK PCGC analysis. |
| `run_h2_ldak_qc` | Workflow toggle for LDAK QC/inflation analysis. |
| `run_h2_ldak_sumher` | Workflow toggle for LDAK SumHer from summary statistics. |
| `run_rg_ldak_sumcors` | Workflow toggle for LDAK SumCors genetic correlation. |
| `heritability_model` | LDAK heritability model used during kinship/REML/HE/PCGC workflows. |
| `ldak_adjust_grm` | Enables adjusted kinship generation before HE/PCGC stages. |
| `ldak_grm_prefix` | Prefix for precomputed LDAK kinship files. |
| `ldak_adjusted_grm_prefix` | Prefix for precomputed adjusted LDAK kinship files. |
| `ldak_reml_prevalence` | Prevalence passed to LDAK REML for binary traits. |
| `ldak_pcgc_prevalence` | Required prevalence passed to LDAK PCGC (`--prevalence`). |
| `ldak_he_subset_prefix` | Optional subset prefix used for genotype error/HE post-processing. |
| `ldak_he_subset_number` | Optional subset count used with HE subset prefix. |
| `ldak_sumher_tagfile` | Tagging file used by LDAK SumHer. |
| `ldak_sumher_check_sums` | Controls SumHer `--check-sums` behavior. |
| `ldak_sumher_prevalence` | Global prevalence override for SumHer binary traits. |
| `ldak_sumher_prevalence_map` | Per-file prevalence map consumed in SumHer orchestration. |
| `ldak_sumher_ascertainment` | Global ascertainment proportion override for SumHer. |
| `ldak_sumher_ascertainment_map` | Per-file ascertainment map consumed in SumHer orchestration. |
| `ldak_sumher_cutoff` | Optional SumHer cutoff value mapped to `--cutoff`. |
| `ldak_sumcors_tagfile` | Tagging file used by LDAK SumCors. |
| `ldak_sumcors_check_sums` | Controls SumCors `--check-sums` behavior. |
| `ldak_sumcors_summary_stats1` | Path to first trait summary statistics for SumCors. |
| `ldak_sumcors_summary_stats2` | Path to second trait summary statistics for SumCors. |
| `ldak_sumstats_liftover` | Enables summary statistics liftover step before SumHer/SumCors. |
| `ldak_sumstats_target_build` | Target genome build for optional liftover. |
| `ldak_sumstats_source_build` | Source genome build (or auto detection) for optional liftover. |
| `ldak_sumstats_frq_filter` | Frequency filter applied during optional liftover harmonization. |
