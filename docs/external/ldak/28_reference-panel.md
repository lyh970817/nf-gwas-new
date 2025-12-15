# Reference Panel

## Overview

A reference panel is required when analyzing summary statistics. It estimates correlations between nearby predictors (linkage disequilibrium). Summary statistics typically contain SNP association study results, so the reference panel should also contain SNP data from ancestrally similar samples.

For example, European association study results often use genotypes from 10,000 UK Biobank samples.

## For Heritability Analysis

When using [SumHer](http://dougspeed.com/sumher/) for SNP heritability, enrichments, genetic correlations, or alpha estimation, use an extensive reference panel with:

- Imputed or sequenced dataset (≥2000 samples)
- SNPs with MAF >0.005
- Information score >0.8
- Typical result: 8-10M SNPs

Per the 2020 *Nature Genetics* paper "Evaluating and improving heritability models using summary statistics," broader panels perform better than limited high-quality SNP-only panels.

## For Prediction Models

When using [MegaPRS](http://dougspeed.com/megaprs/), the reference panel needs only predictors with available summary statistics. Apply the same sample/MAF/information filters, plus exclude:

- SNPs lacking summary statistics
- SNPs with ambiguous alleles

For multiple association studies, create one extensive panel rather than multiple reduced ones.

## 1000 Genomes Reference Panel

For those lacking suitable panels, [The 1000 Genomes Project](https://www.internationalgenome.org/) provides data across European, Asian, and African ancestry groups.

### Setup Scripts

Download raw files:
```
wget https://www.dropbox.com/s/y6ytfoybz48dc0u/all_phase3.pgen.zst
wget https://www.dropbox.com/s/odlexvo8fummcvt/all_phase3.pvar.zst
wget https://www.dropbox.com/s/6ppo144ikdzery5/phase3_corrected.psam
```

Decompress with PLINK2:
```
/home/doug/plink2 --zst-decompress all_phase3_ns.pgen.zst > all_phase3_ns.pgen
/home/doug/plink2 --zst-decompress all_phase3_ns.pvar.zst > all_phase3_ns.pvar
```

Identify non-Finnish Europeans:
```
awk < phase3_corrected.psam '($5=="EUR" && $6!="FIN"){print 0, $1}' > eur.keep
```

Convert to binary PLINK format (autosomal SNPs, MAF>0.01):
```
echo "." > exclude.snps
./plink2 --make-bed --out raw --pgen all_phase3_ns.pgen --pvar all_phase3_ns.pvar --psam phase3_corrected.psam --maf 0.01 --autosome --snps-only just-acgt --max-alleles 2 --rm-dup exclude-all --exclude exclude.snps --keep eur.keep
```

Insert population and sex information:
```
awk '(NR==FNR){arr[$1]=$5"_"$6;ars[$1]=$4;next}{$1=$2;$2=arr[$1];$5=ars[$1];print $0}' phase3_corrected.psam raw.fam > new.fam
```

Add genetic distances:
```
wget https://genetics.ghpc.au.dk/doug/genetic_map_b37.zip
unzip genetic_map_b37.zip
./plink1.9 --make-bed --out ref --bfile raw --fam new.fam --cm-map genetic_map_b37/genetic_map_chr@_combined_b37.txt
```

Your European reference panel will be in `ref.bed`, `ref.bim`, and `ref.fam`.
