# Pre-computed Taggings

This page explains how to perform SNP-based heritability analysis using GWAS summary statistics and pre-computed tagging files. Note that these instructions assume you are using human SNP data; if this is not the case, you should instead calculate taggings yourself.

## Important Considerations

"You should only use a pre-computed tagging file if you have summary statistics for the majority of the SNPs. If you are missing summary statistics for more than, say, 20% of the SNPs in the tagging file, then it is better to calculate taggings yourself."

The site provides pre-computed tagging files for three heritability models (LDAK-Thin, BLD-LDAK, and BLD-LDAK-Lite+Alpha), constructed using UK Biobank data.

## Available Models and Populations

- **Four populations**: GBR (2000 white British), SAS (4214 Indian/Pakistani), EAS (1279 Chinese), AFR (2577 African individuals)
- **Two SNP subsets**: 1.0-1.2M non-ambiguous HapMap3 SNPs and 320-580k directly genotyped SNPs

## SNP Identifier Requirements

Predictor names must be rsIDs. Two reference files are available for converting generic IDs:
- [Details of HapMap3 SNPs](https://genetics.ghpc.au.dk/doug/TaggingFiles/hapmap.snp.details)
- [Details of Directly Genotyped SNPs](https://genetics.ghpc.au.dk/doug/TaggingFiles/genotyped.snp.details)

## Example Analysis

### Download Tagging Files

```bash
wget https://genetics.ghpc.au.dk/doug/TaggingFiles/ldak.thin.hapmap.gbr.tagging.gz
wget https://genetics.ghpc.au.dk/doug/TaggingFiles/bld.ldak.hapmap.gbr.tagging.gz
wget https://genetics.ghpc.au.dk/doug/TaggingFiles/bld.ldak.lite.alpha.hapmap.gbr.tagging.gz
gunzip ldak.thin.hapmap.gbr.tagging.gz
gunzip bld.ldak.hapmap.gbr.tagging.gz
gunzip bld.ldak.lite.alpha.hapmap.gbr.tagging.gz
wget https://www.dropbox.com/s/o7xphugm4mln9xa/pow.txt
```

### Estimate SNP Heritability and Enrichments

```bash
./ldak.out --sum-hers height --summary height.txt --tagfile bld.ldak.hapmap.gbr.tagging --check-sums NO
```

### Estimate Genetic Correlation

```bash
./ldak.out --sum-cors height.neur --summary height.txt --summary2 neur.txt --tagfile ldak.thin.hapmap.gbr.tagging --check-sums NO
```

### Estimate Alpha Parameter

```bash
./ldak.out --sum-hers height2 --summary height.txt --tagfile bld.ldak.lite.alpha.hapmap.gbr.tagging --divisions 7 --powerfile pow.txt --check-sums NO
```
