# Summary of Newly Fetched LDAK Documentation

This file summarizes the 21 new pages fetched during the recursive crawl from the SumHer page.

## New Pages (32-52)

### Core SumHer Functionality
32. **sumher** - Overview of SumHer tool for analyzing GWAS summary statistics
33. **pre-computed-tagging-files** - Using pre-computed UK Biobank tagging files
34. **calculate-taggings** - Creating custom tagging files with reference panels
35. **snp-heritability** - Estimating SNP heritability from summary statistics
36. **heritability-enrichments** - Quantifying heritability enrichment by SNP categories
37. **genetic-correlations** - Estimating genetic correlations between traits
38. **estimate-alpha** - Estimating the selection-related alpha parameter

### Individual-Level Data Analysis
39. **reml-analysis** - Restricted maximum likelihood heritability estimation
40. **blup-estimates** - Best Linear Unbiased Prediction effect size estimation
41. **haseman-elston-regression** - Fast alternative to REML for large datasets

### Prediction Methods
42. **megaprs** - Constructing prediction models from summary statistics
43. **quick-prs** - Simplified PRS construction without reference panel

### Mixed-Model Association Testing
44. **ldak-kvik** - Super-fast linear/logistic mixed-model association analysis
45. **single-predictor-analysis** - Classical linear/logistic regression

### Supporting Documentation
46. **confounding-bias** - Historical confounding bias estimation (deprecated)
47. **per-predictor-heritabilities** - Estimating heritability per SNP
48. **snp-subsets** - Advanced SNP selection for tagging calculations
49. **technical-details** - Detailed heritability model mathematics
50. **bldldak** - BLD-LDAK annotation details (legacy)
51. **calculate-weightings** - LDAK weighting calculation (legacy)
52. **compare-models** - Methods for comparing heritability models

## Key Features Documented

### SumHer Analysis Pipeline
1. Obtain/calculate tagging file
2. Format summary statistics
3. Run regression analysis
4. Interpret results

### Heritability Models
- Human Default Model (recommended)
- LDAK-Thin Model
- BLD-LDAK Model (legacy)
- Baseline LD Model v2.2
- Alpha Model

### Analysis Types
- SNP heritability estimation
- Heritability enrichment by functional categories
- Genetic correlation between traits
- Alpha parameter estimation (MAF-heritability relationship)
- LOCO (leave-one-chromosome-out) analysis

### Pre-computed Resources
- UK Biobank tagging files (GBR, SAS, EAS, AFR populations)
- HapMap3 SNPs (~1.1M) and directly genotyped SNPs (~320-580k)
- LDAK-Thin, BLD-LDAK, and BLD-LDAK-Lite+Alpha models
- 1000 Genomes and HRC correlation matrices for QuickPRS

## Cross-References

These pages extensively cross-reference with the original 31 pages:
- **Quality Control** (02) - Referenced for QC requirements
- **Calculate Kinships** (03) - Used for individual-level data prep
- **File Formats** (24) - Data format specifications
- **Summary Statistics** (31) - Format requirements
- **Reference Panel** (28) - Panel construction guidance

## Workflow Integration

The new pages complete the LDAK workflow documentation:

**Summary Statistics Path:**
sumher → calculate-taggings/pre-computed-tagging-files → snp-heritability/heritability-enrichments/genetic-correlations

**Individual Data Path:**
quality-control → calculate-kinships → reml-analysis/haseman-elston-regression → blup-estimates

**Prediction Path:**
summary-statistics → megaprs/quick-prs → calculate-scores (from original pages)

**GWAS Path:**
quality-control → ldak-kvik/single-predictor-analysis → clumping (not yet fetched)

