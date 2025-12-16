# LDAK-KVIK Performance

LDAK-KVIK is a fast, powerful tool for conducting mixed-model association analysis in genome-wide association studies (GWAS).

## Computational Efficiency

### Runtime and Memory Comparison

When analyzing 690,000 SNPs across varying sample sizes, LDAK-KVIK demonstrated superior performance characteristics:

- **Speed**: LDAK-KVIK is faster than REGENIE for all sample sizes, and for both quantitative and binary phenotypes
- **Memory Usage**: Lower memory consumption than REGENIE for larger cohorts (50k+ individuals)
- **Scalability**: Feasible for analyzing very large datasets with over one million individuals

### Benchmarks vs Other Tools

| Tool | Relative Speed | Memory Usage | Statistical Power |
|------|---------------|--------------|-------------------|
| LDAK-KVIK | Fastest | Low | High |
| BOLT-LMM | Moderate | High | High |
| REGENIE | Moderate | Moderate | Moderate |
| GCTA-LOCO | Slow | High | Moderate |
| fastGWA | Fast | Low | Lower |

## UK Biobank Applications

### Single-SNP Analysis

Testing on 40 quantitative traits from UK Biobank revealed:

- LDAK-KVIK detected **17.9% more significant loci** compared to fastGWA
- BOLT-LMM identified 17.6% additional loci
- REGENIE found 13.5% more loci
- Performance rankings remained consistent when evaluating chi-square statistics

### Gene-Based Analysis

Analysis of 40 quantitative and 20 binary UK Biobank traits showed:

- **LDAK-KVIK-GBAT has improved power over LDAK-GBAT** when analysing quantitative traits, finding 18.4% more significant genes on average
- Performance gains were smaller for binary traits

## Simulation Study Results

### Type 1 Error Control

Across homogeneous, family, and twin datasets with varying heritabilities and causal SNPs:

- **LDAK-KVIK controls type 1 error** for all datasets and scenarios considered
- Maximum mean test statistic: 1.0049 (well-controlled)
- No inflation observed even in highly structured populations

### Statistical Power

Comparing LDAK-KVIK against fastGWA, GCTA-LOCO, REGENIE, and BOLT-LMM:

| Scenario | LDAK-KVIK Rank | Notes |
|----------|---------------|-------|
| Homogeneous population | 1-2 | Tied with BOLT-LMM |
| Family structure | 1-2 | Superior type 1 error control |
| Twin cohorts | 1 | Best overall |
| Binary traits | 1-2 | With saddlepoint approximation |

## Key Performance Conclusions

1. **LDAK-KVIK and BOLT-LMM are the two most powerful mixed-model tools**
2. Both outperform REGENIE and GCTA-LOCO across simulation scenarios
3. fastGWA showed the lowest comparative power
4. LDAK-KVIK is feasible to apply to very large datasets while maintaining statistical rigor and computational efficiency
5. For cloud computing, 4 or fewer threads are recommended for cost efficiency
