# LDSC Workflows

[Back to main README](../../README.md)

This directory contains LDSC-based summary statistics workflows:

- `ldsc_h2.nf` - SNP heritability estimation from GWAS summary statistics
- `ldsc_rg.nf` - Pairwise genetic correlation estimation from GWAS summary statistics

## Inputs

Both workflows consume `summary_stats_dir` files and first run `munge_sumstats.py`.

Required parameters:

- Heritability (`ldsc_h2`):
  - `--ldsc_h2_ref_ld_chr`
  - `--ldsc_h2_w_ld_chr`
- Genetic correlation (`ldsc_rg`):
  - `--ldsc_rg_ref_ld_chr`
  - `--ldsc_rg_w_ld_chr`

## Notes

- `ldsc_rg` evaluates all unique pairwise combinations from `summary_stats_dir`.
- Summary-stat column mapping can be adjusted with shared `sumstats_*` parameters.
