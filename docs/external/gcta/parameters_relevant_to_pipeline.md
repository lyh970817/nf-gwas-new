# GCTA parameters relevant to this pipeline

This file maps `nextflow_schema.json` parameters to the corresponding program behavior/CLI usage.

| Schema parameter | Program usage in pipeline |
|---|---|
| `run_assoc_fastgwa` | Workflow toggle for GCTA FastGWA association analysis. |
| `run_h2_gcta_grm` | Workflow toggle for GCTA GRM generation. |
| `run_h2_gcta_greml` | Workflow toggle for GCTA GREML heritability analysis. |
| `run_h2_gcta_greml_ldms` | Workflow toggle for GCTA GREML-LDMS analysis. |
| `run_rg_gcta_bivariate_greml` | Workflow toggle for GCTA bivariate GREML. |
| `run_rg_gcta_bivariate_greml_ldms` | Workflow toggle for GCTA bivariate GREML-LDMS. |
| `nparts_gcta` | Used by `gcta --make-grm-part` to split GRM computation across parts. |
| `gcta_create_sparse_grm` | Enables sparse GRM creation for FastGWA. |
| `gcta_sparse_cutoff` | Threshold passed to sparse relatedness filtering/GRM creation. |
| `gcta_grm_prefix` | Prefix for precomputed full GRM files (`.grm.bin/.grm.N.bin/.grm.id`). |
| `gcta_sparse_grm_prefix` | Prefix for precomputed sparse GRM files for FastGWA. |
| `gcta_mgrm_file` | Path to `.mgrm` list used by multi-component GREML-LDMS. |
| `gcta_bivariate_phenotype1` | Phenotype column name for trait 1 in bivariate workflows. |
| `gcta_bivariate_phenotype2` | Phenotype column name for trait 2 in bivariate workflows. |
