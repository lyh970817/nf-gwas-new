# LDAK-KVIK Recommendations for UK Biobank RAP

These recommendations apply to UKB-RAP and other cloud-based computing environments.

## Input Genotype File Format

**Primary recommendation:** Use `.bed` files for analysis.

- Avoid `.bgen` format due to increased computational demands and loading time
- Convert genotype data to `.bed` format before analysis, even though dosage information is lost
- This conversion approach yields "near identical GWAS results" despite hardcalling genotypes

## SNP Selection Strategy

For Step 1 analysis:

- Use only directly genotyped SNPs from the `/Bulk/Genotype Results/Genotype calls` folder
- While imputed SNPs can be included, doing so "significantly increases run time" without improving downstream association analysis
- Thinning SNPs to ~500,000 is acceptable for Step 1

## Instance Selection

For Step 1 execution, recommended instance types:

| Instance Type | CPUs | Memory | Use Case |
|--------------|------|--------|----------|
| `mem1_ssd1_v2_x4` | 4 | 8 GiB | General use |
| `mem2_ssd1_v2_x2` | 2 | 8 GiB | Cost-efficient |
| `mem2_ssd2_v2_x2` | 2 | 8 GiB | With SSD |
| `mem3_ssd1_v2_x2` | 2 | 16 GiB | Large datasets |

These instances balance computational requirements—including approximately 10GB memory for full UKB datasets—with cost efficiency.

## Thread Recommendations

Optimal parallelization performance occurs on fewer cores:

- **Step 1:** 2-4 threads recommended
- **Step 2:** 4-8 threads for per-chromosome processing
- **Step 3:** 4 threads typical

Performance gains from additional threads plateau quickly, so more threads primarily increase cost without proportional speedup.

## Cost Optimization Tips

1. **Use `.bed` format** - Faster processing than `.bgen`
2. **Process chromosomes in parallel** in Step 2 using multiple jobs
3. **Limit threads** to 4 or fewer for cost efficiency
4. **Use directly genotyped SNPs** in Step 1 to reduce runtime
5. **Pre-filter data** with standard QC before analysis

## Workflow Summary

1. **Preparation:** Convert phenotypes, covariates, and genotypes to proper format
2. **Step 1:** Run on merged directly-genotyped data (single job)
3. **Step 2:** Run per-chromosome on imputed data (22 parallel jobs)
4. **Merge:** Combine per-chromosome results
5. **Step 3:** Run gene-based analysis if needed

## Additional Resources

- Main LDAK webpage: https://www.ldak.org
- Related GWAS guidance: https://github.com/dnanexus/UKB_RAP/tree/main/GWAS
