# LAVA Documentation Reference

This file contains a reference of the LAVA (Local Analysis of [co]Variant Association) documentation fetched from GitHub.

**Source**: https://github.com/josefin-werme/LAVA
**Version**: 0.1.5

---

## Overview

LAVA is a tool for local genetic correlation (rg) analysis that can:
- Test univariate local genetic signal (local h²) for all phenotypes
- Compute bivariate local rg between phenotype pairs
- Model conditional genetic relations using partial correlation and multiple regression

Reference: Werme et al. (2022) Nature Genetics. https://doi.org/10.1038/s41588-022-01017-y

---

## Input Requirements

### 1. LD Reference Data
- Custom LAVA LD format or PLINK format (.bed/.bim/.fam)
- UK Biobank reference (v1.1) recommended for European ancestry
- 1000 Genomes can be used but may inflate Type I error rates

### 2. Input Info File
Tab-separated with columns:
- `phenotype`: Phenotype IDs
- `cases`: Number of cases (NA for continuous)
- `controls`: Number of controls (NA for continuous)
- `prevalence`: Population prevalence (optional)
- `filename`: Path to summary statistics

### 3. Summary Statistics
Accepted column names:
- SNP ID: `SNP`, `ID`, `SNPID_UKB`, `SNPID`, `MarkerName`, `RSID`, `RSID_UKB`
- Effect allele: `A1`, `ALT`
- Reference allele: `A2`, `REF`
- Sample size: `N`, `NMISS`, `N_analyzed`
- Z-score: `Z`, `T`, `STAT`, `Zscore` (or provide BETA + P)

### 4. Locus Definition File
Columns: `LOC`, `CHR`, `START`, `STOP`
Optional: `SNPS` (semicolon-separated SNP list)

### 5. Sample Overlap File (Optional)
Matrix format from cross-trait LDSC intercepts.

---

## Key Functions

### process.input()
Load and process input data.

```r
input = process.input(
    input.info.file = "input.info.txt",
    sample.overlap.file = "sample.overlap.txt",  # optional
    ref.prefix = "reference_data",
    phenos = c("trait1", "trait2")
)
```

### read.loci()
Read locus definition file.

```r
loci = read.loci("test.loci")
```

### process.locus()
Prepare a locus for analysis.

```r
locus = process.locus(loci[1,], input)
```

### run.univ()
Test univariate local heritability.

```r
run.univ(locus)
# Returns: phen, h2.obs, h2.latent, ascertained, p
```

### run.bivar()
Test bivariate local genetic correlation.

```r
run.bivar(locus)
# Returns: phen1, phen2, rho, rho.lower, rho.upper, r2, r2.lower, r2.upper, p
```

### run.univ.bivar()
Combined analysis with univariate filtering.

```r
run.univ.bivar(locus, univ.thresh = 0.05)
# Returns: list with $univ and $bivar results
```

---

## Example Analysis Script

```r
library(LAVA)

# Load data
loci = read.loci("test.loci")
n.loc = nrow(loci)

input = process.input(
    input.info.file = "input.info.txt",
    sample.overlap.file = "sample.overlap.txt",
    ref.prefix = "reference_data",
    phenos = c("depression", "bmi")
)

# Analyze all loci
u = list()
b = list()

for (i in 1:n.loc) {
    locus = process.locus(loci[i,], input)

    if (!is.null(locus)) {
        loc.info = data.frame(
            locus = locus$id,
            chr = locus$chr,
            start = locus$start,
            stop = locus$stop,
            n.snps = locus$n.snps,
            n.pcs = locus$K
        )

        loc.out = run.univ.bivar(locus, univ.thresh = 0.05)
        u[[i]] = cbind(loc.info, loc.out$univ)
        if (!is.null(loc.out$bivar)) b[[i]] = cbind(loc.info, loc.out$bivar)
    }
}

# Save results
write.table(do.call(rbind, u), "results.univ.lava", row.names=F, quote=F)
write.table(do.call(rbind, b), "results.bivar.lava", row.names=F, quote=F)
```

---

## Sample Overlap Estimation

When sample overlap is unknown, use cross-trait LDSC intercepts:

1. Run LDSC for all phenotype pairs
2. Extract intercepts
3. Build sampling correlation matrix
4. Save as sample overlap file

---

## Advanced Features

### Multiple Regression
Model outcome using multiple predictors:

```r
run.multireg(locus, target='hypothyroidism')
```

### Partial Correlation
Conditional rg between two phenotypes:

```r
run.pcor(locus, target=c("hypothyroidism","diabetes"), phenos='asthma')
```

### eQTL Analysis
For gene expression analysis:

```r
process.eqtl.input(input, "eqtl_data/chr[CHR].stats", chromosomes=14, sample.size=750)
locus = process.eqtl.locus("ENSG00000005700.14", input)
```
