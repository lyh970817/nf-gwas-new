process EXTRACT_PHENOTYPE_META {
    tag "${phenotypes_file.baseName}"

    input:
    path phenotypes_file

    output:
    tuple path(phenotypes_file), path("phenotype.meta.txt"), emit: phenotype_meta

    script:
    """
    python ${projectDir}/bin/extract_phenotype_meta.py ${phenotypes_file} phenotype.meta.txt
    """
}
