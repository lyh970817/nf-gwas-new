# Summary statistics prevalence mapping format

Use this format with:
- `--ldak_sumher_prevalence_map`
- `--ldak_sumher_ascertainment_map`

Each non-empty, non-comment line must contain two whitespace-separated fields:

```
<summary_stats_filename> <prevalence>
```

Example:

```
# filename prevalence
height.sumstats.txt 0.01
t2d.sumstats.txt 0.08
```

Notes:
- `summary_stats_filename` must match the **basename** in `--summary_stats_dir` (e.g., `file.name`).
- `prevalence` must be between 0 and 1.
- If a file has no entry, prevalence is omitted for that trait by default.
- If a mapping file is provided, legacy global prevalence options are ignored:
  - `--ldak_sumher_prevalence`

For ascertainment mapping, use the same layout but with ascertainment values:

```
# filename ascertainment
height.sumstats.txt 0.50
t2d.sumstats.txt 0.18
```

If an ascertainment mapping file is provided, legacy global ascertainment options are ignored:
- `--ldak_sumher_ascertainment`
