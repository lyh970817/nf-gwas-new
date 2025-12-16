# LCV (Latent Causal Variable Model) Reference

Source: https://github.com/lukejoconnor/LCV

## Overview

LCV is a method for inferring genetically causal relationships using GWAS data.

## Requirements

1. **LD scores** (non-stratified, with ancestry matching your GWAS data)
   - Download from: https://data.broadinstitute.org/alkesgroup/LDSCORE/
   - Or compute using LDSC: https://github.com/bulik/ldsc

2. **Signed summary statistics**
   - Effect size estimates (per-normalized-genotype effect size)
   - Or Z-scores

## R Implementation

### Main Functions

- `RunLCV.R`: Runs LCV on summary statistics for two traits
- `MomentFunctions.R`: Functions to compute sample moments used by LCV
- `SimulateLCV.R`: Generates simulated summary statistics

### RunLCV Function

```r
RunLCV <- function(ell, z.1, z.2, no.blocks=100, crosstrait.intercept=1,
                   ldsc.intercept=1, weights=1/pmax(1,ell),
                   sig.threshold=.Machine$integer.max, n.1=1, n.2=1,
                   intercept.12=0)
```

**Parameters:**
- `ell`: M×1 vector of LD scores
- `z.1`: M×1 vector of marginal effects on trait 1
- `z.2`: M×1 vector of effects on trait 2
- `no.blocks`: Number of jackknife blocks (default: 100)
- `crosstrait.intercept`: Estimate cross-trait LDSC intercept (0 or 1)
- `ldsc.intercept`: Estimate LDSC intercept (0 or 1)
- `weights`: M×1 regression weight vector
- `sig.threshold`: Chi-square threshold for discarding large-effect SNPs
- `n.1, n.2`: Sample sizes for traits 1 and 2
- `intercept.12`: Covariance between sampling errors

**Returns:**
- `zscore`: Partial genetic causality test statistic
- `pval.gcpzero.2tailed`: Two-tailed p-value
- `gcp.pm`: Posterior mean genetic causal proportion
- `gcp.pse`: Posterior standard error
- `rho.est`: Estimated genetic correlation
- `rho.err`: Standard error of correlation estimate
- `pval.fullycausal`: Two p-values for GCP=1 or GCP=-1
- `h2.zscore`: Two z-scores for trait heritability

## Important Notes

1. **Sorting**: Summary statistics and LD scores must be sorted by genomic position (block-jackknife requires contiguous SNPs)

2. **Ancestry**: Datasets should have approximately the same ancestry as each other and with LD scores

3. **MAF filtering**: Recommend using SNPs with allele frequency > 0.05

4. **MHC exclusion**: Recommend removing MHC region in all analyses

## Reference

O'Connor, L.J. and A.L. Price. "Distinguishing genetic correlation from causation across 52 diseases and complex traits." Nature genetics (2018).

Paper link: https://rdcu.be/bajzC

## Contact

loconnor@broadinstitute.org
