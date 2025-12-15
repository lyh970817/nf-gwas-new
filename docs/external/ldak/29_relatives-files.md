# Relatives Files

## Overview

The relatives file is a required input when using [TetraHer and QuantHer](https://dougspeed.com/tetraher/). It should contain either five or six columns with specific information about related individual pairs.

## File Structure

**Columns 1 & 2:** Two IDs for the first individual in each pair

**Columns 3 & 4:** Two IDs for the second individual in each pair

**Column 5:** Relatedness between the pair (as Coefficient of Relatedness, ranging 0-1)

**Column 6 (optional):** Environmental similarity between relatives

The relatedness value represents the [Coefficient of Relatedness](https://en.wikipedia.org/wiki/Coefficient_of_relationship). Examples include:
- 1.0 for identical twins
- 0.5 for full-siblings and parent-child pairs
- 0.25 for half-siblings

Generally, include only close relatives (relatedness > 0.1) since distant pairs contribute minimally to heritability estimation.

## Example Files

From the Test Datasets, the first two lines of example files:

```
head -n 2 disease.relatives
27809 27809 29595 29595 0.301
49531 49531 22574 22574 0.479

head -n 2 disease.enviro
27809 27809 29595 29595 0.301 0
49531 49531 22574 22574 0.479 1
```

The first file indicates relatedness estimates (0.30 for likely half-siblings, 0.48 for likely full siblings). The second file adds environmental similarity columns (0 = no common environment, 1 = same environment).

## Constructing the First Five Columns

### Using Pedigree Information

If pedigree data is available, format existing related pairs to match LDAK requirements: individual IDs, second individual IDs, and their relatedness value.

### Using SNP Data

Two main approaches exist:

**Identity by Descent:** Use [KING software](https://www.kingrelatedness.com/) to identify related pairs.

**Identity by State:** Use LDAK by:
1. [Calculating Kinships](https://dougspeed.com/calculate-kinships/)
2. [Filtering Relatedness](https://dougspeed.com/filter-relatedness/)

### Converting from Sparse GRM Format

If you have a sparse GRM in GCTA format (sparse.grm.id and sparse.grm.sp), convert using AWK:

```bash
awk '(NR==FNR){arr[NR-1]=$1;arr2[NR-1]=$2;next}{print arr[$1], arr2[$1], arr[$2], arr2[$1], $3}' sparse.grm.id sparse.grm.sp > sparse.pairs
```

## Adding the Sixth Column (Environmental Similarity)

The sixth column is optional. Two common approaches:

1. **Assign 1 to full-siblings and identical twins, 0 to others** - Based on likelihood of shared household
2. **Assign 1 to all pairs** - More conservative approach

The document acknowledges both approaches have limitations given the difficulty of accurately estimating environmental effects.

## Example: Using Test Data

Using binary PLINK files (human.bed, human.bim, human.fam) with [KING v2.3.0](https://www.kingrelatedness.com/):

### Identity by Descent Approach

```bash
./king -b human.bed --related --degree 2
```

Output file king.kin0 contains pairs with coefficient of relatedness ≥ 0.17. Convert to LDAK format (multiply kinship by 2 to get relatedness):

```bash
awk < king.kin0 '(NR>1){print $1, $2, $3, $4, $10*2}' > human.pairs.king
```

### Identity by State Approach

Calculate kinships using Uniform [Heritability Model](https://dougspeed.com/heritability-model/):

```bash
./ldak.out --calc-kins-direct Uniform --bfile human --power -1
```

Filter relatedness:

```bash
./ldak.out --filter Uniform --grm Uniform --min-rel .1
```

The output file Uniform.pairs is ready for use with TetraHer and QuantHer.
