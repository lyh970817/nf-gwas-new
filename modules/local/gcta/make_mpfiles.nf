process MAKE_MPFILES {
    tag "${filename}"

    input:
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file), val(range)

    output:
    path "${filename}.mpfile", emit: mpfile_part

    script:
    """
    # Create a part file for this chromosome
    # Format: filename pgen_path psam_path pvar_path
    echo "${filename} ${plink2_pgen_file} ${plink2_psam_file} ${plink2_pvar_file}" > ${filename}.mpfile
    """
}
