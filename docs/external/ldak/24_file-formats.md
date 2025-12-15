# File Formats

LDAK accepts genetic data in many formats. When analysing SNP data, it is easiest to use bed format (binary PLINK) which is designed to store hard-coded SNP genotypes (all values must be 0, 1, 2 or NA). If you have genotype probabilities (i.e., the probability that each SNP is 0, 1 or 2), it is most common to use the BGEN format. Gen format (sometimes referred to as Oxford or Chiamo format) is highly flexible; it is designed for reading genotype probabilities created by IMPUTE2, but can also accommodate, say, the output from other imputation software, haplotypes or non-genotype data (e.g., gene expressions). The final option is Sparse Partitioning (SP) format, which simply requires data in a large matrix (rows are predictors, columns are samples). Note that there are three versions of the SP format (one text and two binary).

To filter either samples or predictors, see the Data Filtering options. LDAK is usually applied to SNP data, in which case all predictors take values between 0 and 2 (representing the count of the A1 allele). However, LDAK can also be applied to other datatypes; for this your data should be in either gen or SP format and you should use the option `--SNP-data NO`.

## Binary PLINK (Bed) Format

Use the option `--bfile <datastem>`; LDAK will then expect to find the files `<datastem>.bed`, `<datastem>.bim` and `<datastem>.fam`.

- **`<datastem>.bed`** contains the SNP genotypes, coded as 0, 1, 2 or missing, based on the count of the A1 allele
- **`<datastem>.bim`** has one row per SNP and six columns, which provide the chromosome, name, genetic and physical distance of each SNP, as well as the bases corresponding to the A1 and A2 alleles (note that genetic distances are often not provided, in which case the third column values will be zero)
- **`<datastem>.fam`** has one row per individual and six columns, which provide the Individual ID, the Family ID, as well as Maternal and Paternal IDs, Sex and Phenotype

Note that LDAK only uses the first two IDs; the remaining four columns are ignored (so to use sex as a covariate or to provide phenotypic values, these need to be supplied separately). For more details, see the [PLINK website](https://www.cog-genomics.org/plink/2.0/input#bed).

## BGEN Format

Use the option `--bgen <bgenfile>` to specify the file containing genotype probabilities. If `<bgenfile>` does not contain sample IDs, you must provide these separately using `--sample <samplefile>`.

The BGEN format is complicated (see [this page](https://www.chg.ox.ac.uk/~gav/bgen_format/spec/latest.html) for a full specification). However, be aware that there are multiple versions (listed on [this page](https://www.chg.ox.ac.uk/~gav/bgen_format/history.html)). The most common version is 1.2 (typically with either 8 or 16 bit encoding). LDAK also accommodates version 1.1, but does not currently accept version 1.3 (but contact Doug if you would like this added).

If using `--samples`, then `<samplefile>` should have at least two columns, providing FID and IID, and exactly two header rows (LDAK will only use the first two columns, so any extra information, such as sex and missingness rate, will be ignored).

## Gen Format

Use the option `--gen <genfile>` to specify the file containing the predictor values, as well as `--sample <samplefile>` or `--fam <famfile>` to provide the sample IDs, and `--bim <bimfile>` or `--oxford-single-chr <integer>` to provide the predictor annotations. Note that `<genfile>` can either contain raw text or be a gzipped file.

The options `--gen-skip` and `--gen-headers` specify, respectively, how many header rows (typically 0 or 1) and header columns (typically 0 to 5) the predictor file has, while the format of the predictor values is determined by `--gen-probs`:

- **0** - haplotypes - predictor values should be "0 0", "0 1", "1 0" or "1 1"
- **1** - dosages - predictor values provide the (expected) count of the A1 allele
- **2** - two probabilities - providing probabilities of being AA or AB
- **3** - three probabilities - providing probabilities of being AA, AB or BB
- **4** - four probabilities - providing probabilities of being AA, AB, BB or NA

where A and B denote the A1 and A2 alleles

The default gen format assumes `<genfile>` has no header row, five header columns (blank, SNP ID, BP, A1, A2) and three probabilities, matching the output from IMPUTE2.

## Sparse Partitioning (SP) Format

Use the option `--sp <datastem>`; LDAK will then expect to find the files `<datastem>.sp`, `<datastem>.bim` and `<datastem>.fam`.

- **`<datastem>.sp`** is a text file (space delimited) containing the predictor values. It has one row per predictor and one column per sample, such that element (i,j) provides the value of the ith predictor for the jth individual. Missing values should be denoted by NA.
- **`<datastem>.bim`** and **`<datastem>.fam`** are the bim and fam files, in PLINK format, as described above.

Note that `--sp <datastem>` is equivalent to using `--gen <datastem>.sp`, `--bim <datastem>.bim` and `--fam <datastem>.fam`, with `--gen-skip 0`, `--gen-headers 0` and `--gen-probs 1`. If instead of `--sp <datastem>`, you use `--sp-gz <datastem>`, then LDAK will expect the predictors to be stored in the gzipped file `<datastem>.sp.gz`.

## Old Binary SP Format

Use the option `--sped <datastem>`; LDAK will then expect to find the files `<datastem>.sp`, `<datastem>.bim` and `<datastem>.fam`.

This is the same as SP format, except the file containing predictor values is in binary format. You can create this file using the command `--make-sped <outfile>` (see [Make Data](http://dougspeed.com/making-data/)). Note that this format has been largely superseded by the new binary SP format below.

## New Binary SP Format

Use the option `--speed <datastem>`; LDAK will then expect to find the files `<datastem>.sp`, `<datastem>.bim` and `<datastem>.fam`.

This is the same as SP format, except the file containing predictor values is in binary format. You can create this file using the command `--make-speed <outfile>` (see [Make Data](http://dougspeed.com/making-data/)). This format is more efficient than the old binary SP format, because it saves values at lower resolution. By default, it allows for 255 different values (if using genotype data, this means that dosages are stored to 2 decimal places); if you add `--speed-long YES`, this increases to 65535 different values.
