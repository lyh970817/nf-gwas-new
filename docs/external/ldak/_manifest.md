# LDAK Documentation Manifest (Updated)

This directory contains comprehensive documentation for LDAK (Linkage Disequilibrium Adjusted Kinships) software fetched from [DougSpeed.com](https://dougspeed.com/).

**Total Pages:** 52+ (31 original + 21 from SumHer crawl + summary documents)
**Source:** https://dougspeed.com/
**Date Initially Fetched:** 2025-12-13
**Date Updated:** 2025-12-13

---

## Documentation Structure

### Part 1: Core Heritability Analysis (Individual-Level Data) [01-08]
1. **REML / HE / PCGC** - `01_reml-and-blup.md` - Overview of heritability methods
2. **Quality Control** - `02_quality-control.md` - Sample/predictor QC, inflation testing
3. **Calculate Kinships** - `03_calculate-kinships.md` - Kinship matrix computation
4. **Genomic Partitioning** - `04_genomic-partitioning.md` - Chromosome-based heritability
5. **Heritability Model** - `05_heritability-model.md` - Model comparisons and recommendations
6. **PCGC Regression** - `06_pcgc-regression.md` - Binary trait heritability
7. **More Features** - `07_more-functions.md` - Index of additional features (12 topics)
8. **Other Details** - `08_other-details.md` - Technical documentation hub (12 topics)

### Part 2: Additional Analysis Tools [09-20]
9. **Adjust Kinships** - `09_adjust-kinships.md` - Covariate-adjusted kinship matrices
10. **Calculate Scores** - `10_calculate-scores.md` - Polygenic risk scores (PRS)
11. **Calculate Statistics** - `11_calculate-statistics.md` - Allele frequencies and missingness
12. **Filter Relatedness** - `12_filter-relatedness.md` - Remove related samples
13. **Jackknife** - `13_jackknife.md` - PRS accuracy assessment
14. **Make Data** - `14_make-data.md` - Format conversion and data manipulation
15. **Manipulate Kinships** - `15_manipulate-kinships.md` - Add/subtract kinship matrices (LOCO)
16. **Principal Components** - `16_principal-components.md` - PCA for population structure
17. **Pseudo Summaries** - `17_pseudo-summaries.md` - Cross-validation without individual data
18. **Simulate Data** - `18_simulate-data.md` - Generate synthetic genotypes/phenotypes
19. **TetraHer and QuantHer** - `19_tetraher.md` - Heritability in related samples
20. **Thin Predictors** - `20_thin-predictors.md` - LD-based SNP pruning

### Part 3: Technical Documentation & Reference [21-31]
21. **1000 Genomes Project** - `21_1000-genomes-project.md` - Reference panel construction
22. **Advanced Options** - `22_advanced-options.md` - Working directory and random seed
23. **Data Filtering** - `23_data-filtering.md` - Extract/exclude/keep/remove options
24. **File Formats** - `24_file-formats.md` - BED, BGEN, Gen, SP format specifications
25. **High-LD Regions** - `25_high-ld-regions.md` - High-LD region exclusion for PCA
26. **Kinship Formats** - `26_kinship-formats.md` - Binary, gzipped, raw kinship storage
27. **Phenotypes and Covariates** - `27_phenotypes-and-covariates.md` - PLINK format specs
28. **Reference Panel** - `28_reference-panel.md` - Panel requirements for summary stats
29. **Relatives Files** - `29_relatives-files.md` - TetraHer/QuantHer input format
30. **Sample Subsets** - `30_subsets.md` - Cohort specification for batch effects
31. **Summary Statistics** - `31_summary-statistics.md` - GWAS summary stats format

### Part 4: SumHer - Summary Statistics Analysis [32-38]
32. **SumHer** - `32_sumher.md` - Overview of summary statistics analysis tool
33. **Pre-computed Tagging Files** - `33_pre-computed-tagging-files.md` - UK Biobank taggings
34. **Calculate Taggings** - Documentation in `summary_of_new_pages.md` - Custom tagging file creation
35. **SNP Heritability** - Summary statistics-based heritability estimation
36. **Heritability Enrichments** - Functional category enrichment quantification
37. **Genetic Correlations** - Cross-trait genetic correlation estimation
38. **Estimate Alpha** - Selection-related parameter estimation

### Part 5: Advanced Individual-Level Analysis [39-41]
39. **REML Analysis** - Detailed REML documentation with examples
40. **BLUP Estimates** - Best Linear Unbiased Prediction effect sizes
41. **Haseman-Elston Regression** - Fast REML alternative for large datasets

### Part 6: Prediction Methods [42-43]
42. **MegaPRS** - Prediction models from summary statistics
43. **QuickPRS** - Simplified PRS without reference panel (1000G/UKBB/HRC cors)

### Part 7: Association Testing [44-45]
44. **LDAK-KVIK** - Fast mixed-model association testing (3-step workflow)
45. **Single-Predictor Analysis** - Classical linear/logistic regression

### Part 8: Model Comparison & Legacy Methods [46-52]
46. **Confounding Bias** - Deprecated inflation estimation
47. **Per-Predictor Heritabilities** - SNP-level heritability estimates
48. **SNP Subsets** - Reference/regression/heritability SNP definitions
49. **Technical Details** - Heritability model mathematics
50. **BLD-LDAK** - Baseline LD Model annotations (legacy, 66 categories)
51. **Calculate Weightings** - LDAK weighting calculation (legacy)
52. **Compare Models** - Model comparison via log-likelihood/AIC

---

## Workflow Quick Reference

### Summary Statistics Workflow
```
format_data (31) → calculate_taggings (34) OR download_precomputed (33) →
  → snp_heritability (35) / heritability_enrichments (36) / genetic_correlations (37)
```

### Individual-Level Data Workflow
```
quality_control (02) → calculate_kinships (03) →
  → reml_analysis (39) / haseman_elston (41) / pcgc (06) →
    → blup_estimates (40) [optional]
```

### GWAS Workflow
```
quality_control (02) → ldak_kvik (44) OR single_predictor (45) →
  → clumping [not fetched] → megaprs (42)
```

### Prediction Workflow
```
summary_statistics (31) → megaprs (42) OR quick_prs (43) →
  → calculate_scores (10) → jackknife (13)
```

---

## Heritability Models Summary

| Model | Use Case | Implementation |
|-------|----------|----------------|
| **Human Default** | General heritability (recommended) | `--ignore-weights YES --power -.25` |
| **Uniform (GCTA)** | Simple baseline | `--ignore-weights YES --power -1` |
| **LDAK-Thin** | Alternative to GCTA | Thin + weights + `--power -.25` |
| **Baseline LD v2.2** | Enrichment analysis | `--annotation-number 86 --annotation-prefix BaselineLD` |
| **Alpha Model** | LDAK-KVIK, MegaPRS | Estimated from data |
| **BLD-LDAK** | Legacy enrichments | 66 annotations (deprecated) |

---

## Pre-computed Resources

### Tagging Files (UK Biobank-based)
- **Populations:** GBR, SAS, EAS, AFR
- **SNP Sets:** HapMap3 (~1.1M), Genotyped (~320-580k)
- **Models:** LDAK-Thin, BLD-LDAK, BLD-LDAK-Lite+Alpha

### QuickPRS Correlations
- **Data Sources:** 1000 Genomes, UK Biobank, HRC
- **Populations:** AFR, AMR, CARAFR, CEU, CHI, EAS, FIN, INDPAK, SAS, UK
- **SNP Sets:** HapMap3 (~1.1M), Imputed (~2.5M)

---

## Key Cross-References

**For Quality Control:** 02 (quality-control), 23 (data-filtering), 12 (filter-relatedness)
**For Heritability:** 01 (reml-he-pcgc), 03 (calculate-kinships), 05 (heritability-model), 39 (reml-analysis), 41 (haseman-elston)
**For Summary Stats:** 31 (summary-statistics), 32 (sumher), 33-38 (sumher components)
**For Prediction:** 10 (calculate-scores), 42 (megaprs), 43 (quick-prs), 13 (jackknife)
**For GWAS:** 44 (ldak-kvik), 45 (single-predictor-analysis)
**For Technical Details:** 24 (file-formats), 27 (phenotypes-covariates), 49 (technical-details)

---

## File Organization

```
docs/external/ldak/
├── 01-31_*.md          # Original 31 documentation pages
├── 32-33_*.md          # SumHer core pages (saved as markdown)
├── summary_of_new_pages.md  # Comprehensive summary of pages 34-52
├── urls.txt            # Original 8 URLs
├── urls_new.txt        # 21 new URLs from recursive fetch
└── _manifest.md        # This file (updated version)
```

---

## Notes

- **Full markdown content** available for pages 01-33
- **Comprehensive summary** provided in `summary_of_new_pages.md` for pages 34-52
- **Fetched content** stored in initial WebFetch results for all 52+ pages
- **Cross-references** maintained between original and new documentation
- **Workflow integration** documented for complete analysis pipelines

### Important: Unfetched URLs

**When reviewing this documentation to answer user questions, Claude should:**
1. Check if any URLs referenced in the documentation markdown have not been fetched
2. If an unfetched URL appears to be important for providing a complete answer, notify the user with:
   - The URL that has not been fetched
   - Why it might be important for the current question
   - Offer to fetch it if the user would like more complete information

This ensures users are aware when the answer might be incomplete due to missing documentation pages.

---

**Last Updated:** 2025-12-13
**Documentation Version:** Complete as of recursive crawl from sumher page
**For Latest Updates:** Visit https://dougspeed.com/
**Total URLs Fetched:** 29 (8 original + 21 from recursive crawl)
