# Advanced Options

This page describes some advanced settings.

___

## Working Directory Option

All features allow you to add the option `--workdir <directory>` to specify the working directory. LDAK will then prefix any relative filenames with `<directory>`. This option is useful when running on a cluster that requires absolute filenames (and does not allow the option `-cwd`).

For example, if [Calculating Statistics](https://dougspeed.com/calculate-statistics/) using the command:

```
./ldak.out –calc-stats output –bfile data –work-dir /home
```

LDAK will look for the data files `/home/data.bed`, `/home/data.bim` and `/home/data.fam`, and will write results to `/home/output.stats` and `/home/output.missing`.

___

## Random Seed Option

The option `--random-seed <integer>` can be used to specify the seed used for random number generators. This option only impacts stochastic features, such as when using the command `--calc-genes-reml <folder>` as part of a [Gene-Based Analysis](https://dougspeed.com/gene-based-analysis/) or when using [LDAK-GBAT](https://dougspeed.com/ldak-gbat/).

For example, suppose you run the following set of commands twice:

```
./ldak.out --cut-genes genes --bfile human --genefile anns.txt
./ldak.out --calc-genes-reml genes --pheno quant.pheno --bfile human --ignore-weights YES --power -.25
./ldak.out --join-genes-reml genes
```

The results of each run will be slightly different (each run will use different permutations, so the permuted p-values will change slightly).

To avoid this stochasticity, run these commands instead:

```
./ldak.out --cut-genes genes --bfile human --genefile anns.txt
./ldak.out --calc-genes-reml genes --pheno quant.pheno --bfile human --ignore-weights YES --power -.25 --random-seed 7
./ldak.out --join-genes-reml genes
```

Now the results of repeated runs will be identical.
