---
layout: page
title: Configuration
has_children: true
nav_order: 4
---

## Configuration

Before running nf-gwas, a Nextflow config file must be prepared. This file includes both [pipeline parameters](../params/params) and [cpus/memory directives](directives). Additionally, the correct [profile](profiles) must be specified before executing the pipeline. Fully working examples including different parameters can be found [here](https://github.com/genepi/nf-gwas/tree/main/conf/tests).

## Examples
The nf-gwas pipeline currently supports imputed files in **VCF** format (coming from [Michigan Imputation Server](https://imputationserver.sph.umich.edu/)). Please find below a working config file to run nf-gwas.

###  VCF files
The following minimal configuration file runs an additive model using VCF data from e.g. Michigan Imputation Server.

```
params {
  project                       = 'mis-gwas'
  genotypes_prediction          = '/data/genotyped/allChrs.{bim,bed,fam}'
  genotypes_association         = '/data/imputed/vcfs/*vcf.gz'
  genotypes_build               = 'hg19'
  genotypes_association_format  = 'vcf'
  phenotypes_filename           = 'phenotype/my_phenotypes.txt'
  phenotypes_columns            = 'phenotype1, phenotype2'
  phenotypes_binary_trait       = false
  regenie_test                  = 'additive'
  prune_enabled                 = true
}

process {

    withLabel: 'process_plink2' {
        cpus   =  4
        memory =  32.GB
    }

    //
    withLabel: 'required_memory_report' {
        memory =  32.GB
    }

    withName: 'REGENIE_STEP1|REGENIE_STEP2'
    {
        cpus   = 8
        memory = 16.GB
    }

}
```
