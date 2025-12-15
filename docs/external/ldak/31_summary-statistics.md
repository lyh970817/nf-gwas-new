# Summary Statistics

## Overview

This page explains the format of summary statistics files used to store results from single-SNP GWAS. Each file requires a header row and typically contains five or six columns (note: column names are case-sensitive).

## Required Columns

Every file must include these four columns:

- **Predictor** - the SNP name
- **A1** - the test allele (single character: A, C, G, or T)
- **A2** - the other allele (single character: A, C, G, or T)
- **n** - number of samples tested for the SNP

## Statistical Options

Choose one of the following four options:

### Option 1
- **Z** - Gaussian test statistic (or t-statistic)

### Option 2
- **BETA** - estimated effect size of test allele (log odds for logistic regression)
- **SE** - standard error of effect size

### Option 3
- **Stat** - chi-squared test statistic (1 degree of freedom)
- **Direction** - effect direction (+1 or -1, or estimated effect size)

### Option 4
- **P** - p-value
- **Direction** - effect direction (+1 or -1, or estimated effect size)

## Recommended Column

- **A1Freq** - frequency of the A1 allele

## Key Points to Note

1. SNP names must be unique and consistent with the Reference Panel
2. Multi-character alleles are ignored
3. Exclude ambiguous alleles (A&T or C&G) to avoid strand errors
4. Use total sample size if per-SNP sizes unavailable
5. Only use carefully quality-controlled GWAS results
6. Additional columns are permitted but ignored by LDAK

## SNP Naming Conventions

Most GWAS results use rsIDs, though some use generic names like "10:9960129" or "10:9960129_A_G".

**Important:** SNP names in summary statistics must match those in your reference panel. Generic names depend on genome assembly versions (Chr37/hg19 vs Chr38/hg38), so coordinate conversion may be necessary using the LiftOver Tool.

## Examples

### Height Analysis (GIANT Consortium)

Download and process height results from 253k individuals:

```bash
wget https://portals.broadinstitute.org/collaboration/giant/images/0/01/GIANT_HEIGHT_Wood_et_al_2014_publicrelease_HapMapCeuFreq.txt.gz

gunzip -c GIANT_HEIGHT_Wood_et_al_2014_publicrelease_HapMapCeuFreq.txt.gz | awk '(NR==1){print "Predictor A1 A2 Z n A1Freq"}(NR>1){snp=$1;a1=$2;a2=$3;freq=$4;maf=freq;if(freq>0.5){maf=1-freq};effect=$5;se=$6;z=effect/se;n=$8; if(a1!=a2 && (a1=="A"||a1=="C"||a1=="G"||a1=="T") && (a2=="A"||a2=="C"||a2=="G"||a2=="T") && maf>0.01 && n>200000){print snp, a1, a2, z, n, freq}}' - | grep -v NA > height.txt

head -n 5 height.txt
```

Output:
```
Predictor A1 A2 Z n A1Freq
rs4747841 A G -0.37931 253213 0.551
rs4749917 T C 0.37931 253213 0.436
rs737656 A G -2.06667 253116 0.367
rs737657 A G -2.06667 252156 0.358
```

Check for duplicates:
```bash
awk < height.txt '{print $1}' | sort | uniq -d | head
```

### Neuroticism Analysis (Nagel et al.)

Process neuroticism results with information score filtering:

```bash
gunzip -c sumstats_neuroticism_ctg_format.txt.gz | awk '(NR==1){print "Predictor A1 A2 Z n A1Freq"}(NR>1){snp=$1;a1=$5;a2=$6;freq=$7;maf=$8;z=$9;n=$11;info=$12; if(a1!=a2 && (a1=="A"||a1=="C"||a1=="G"||a1=="T") && (a2=="A"||a2=="C"||a2=="G"||a2=="T") && maf>0.01 && n>350000 && info>0.95){print snp, a1, a2, z, n, freq}}' - > neur.txt

head -n 5 neur.txt
```

Output:
```
Predictor A1 A2 Z n A1Freq
rs146277091 A G 1.06 370996 0.0367696
rs3094315 A G -0.263 371912 0.829189
rs3131972 A G 0.137 372903 0.173757
rs3115860 A C 0.057 370472 0.860653
```

These examples use AWK for efficient processing of large GWAS result files.
