# 1000 Genomes Project

## Overview

The [1000 Genomes Project](https://www.internationalgenome.org/) sequenced 2504 samples from 26 populations across the world. These data are regularly used to infer ancestry and can serve as a reference panel for various analyses, though "the reference panel contains at least 2000 samples" is recommended.

## Construction Scripts

Scripts are provided for building a 1000 Genome dataset. Both [PLINK1.9](https://www.cog-genomics.org/plink/1.9/) and [PLINK2](https://www.cog-genomics.org/plink/2.0/) must be installed. The scripts restrict variants to minor allele frequency above 0.01.

### Download Raw Files

```bash
wget https://www.dropbox.com/s/y6ytfoybz48dc0u/all_phase3.pgen.zst
wget https://www.dropbox.com/s/odlexvo8fummcvt/all_phase3.pvar.zst
wget https://www.dropbox.com/s/6ppo144ikdzery5/phase3_corrected.psam
```

### Decompress Files

```bash
./plink2 --zst-decompress all_phase3.pgen.zst > all_phase3.pgen
./plink2 --zst-decompress all_phase3.pvar.zst > all_phase3.pvar
```

### Convert to Binary PLINK Format

```bash
echo "." > exclude.snps
./plink2 --make-bed --out raw --pgen all_phase3.pgen --pvar all_phase3.pvar --psam phase3_corrected.psam --maf 0.01 --autosome --snps-only just-acgt --max-alleles 2 --rm-dup exclude-all --exclude exclude.snps
```

### Insert Population and Sex Information

```bash
awk '(NR==FNR){arr[$1]=$5"_"$6;arr2[$1]=$4;next}{$1=$2;$2=arr[$1];$5=arr2[$1];print $0}' phase3_corrected.psam raw.fam > new.fam
```

### Download Genetic Distances and Create Final Dataset

```bash
wget https://genetics.ghpc.au.dk/doug/genetic_map_b37.zip
unzip genetic_map_b37.zip
./plink1.9 --make-bed --out 1000g --bfile raw --fam new.fam --cm-map genetic_map_b37/genetic_map_chr@_combined_b37.txt
```

Upon successful completion, the reference panel is stored in binary PLINK format as `1000g.bed`, `1000g.bim`, and `1000g.fam`.
