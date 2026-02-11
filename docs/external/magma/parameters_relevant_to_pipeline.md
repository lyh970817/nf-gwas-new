# MAGMA parameters relevant to this pipeline

This file maps `nextflow_schema.json` parameters to the corresponding program behavior/CLI usage.

| Schema parameter | Program usage in pipeline |
|---|---|
| `run_magma_gene_based` | Workflow toggle for MAGMA gene-based analysis. |
| `run_magma_gene_set` | Workflow toggle for MAGMA gene-set analysis. |
| `magma_reference_plink` | Reference PLINK prefix used as `--bfile` for annotation/gene analysis. |
| `magma_gene_annot` | Precomputed MAGMA gene annotation file (`--gene-annot`). |
| `magma_gene_loc` | Gene location file used to generate annotation (`--gene-loc`). |
| `magma_set_annot` | Gene-set annotation file (`--set-annot`). |
| `magma_gene_results_dir` | Directory with precomputed `*.genes.raw` files for gene-set-only runs. |
| `magma_gene_input_mode` | Selects MAGMA input mode: summary statistics (`sumstats`) or raw results (`raw`). |
| `magma_raw_extra_args` | Extra CLI flags for raw gene analysis command. |
| `magma_window_up_kb` | Upstream window size (kb) for annotation around gene start. |
| `magma_window_down_kb` | Downstream window size (kb) for annotation around gene end. |
| `magma_gene_model` | Model string passed to MAGMA `--model` for gene analysis. |
| `magma_gene_extra_args` | Extra CLI flags appended to MAGMA gene analysis command. |
| `magma_set_model` | Model string passed to MAGMA `--model` for gene-set analysis. |
| `magma_set_extra_args` | Extra CLI flags appended to MAGMA gene-set command. |
