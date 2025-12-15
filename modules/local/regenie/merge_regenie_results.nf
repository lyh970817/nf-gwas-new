process MERGE_REGENIE_RESULTS {

    tag "${output_name}"

    publishDir "${params.pubDir}/regenie/merged", mode: 'copy', pattern: '*.regenie.gz'

    input:
    tuple val(output_name), path(regenie_files)

    output:
    tuple val(output_name), path("${output_name}_merged.regenie.gz"), emit: merged_results

    shell:
    '''
    #!/bin/bash
    set -e

    # Get sorted list of input files (ensures consistent chromosome ordering)
    files=($(ls -v *.regenie.gz))

    # Extract header from first file (using subshell to avoid SIGPIPE issues)
    zcat "${files[0]}" | head -n 1 > "!{output_name}_merged.regenie" || true

    # Append data from all files (skipping headers)
    for file in "${files[@]}"; do
        zcat "$file" | tail -n +2 >> "!{output_name}_merged.regenie" || true
    done

    # Compress final output
    gzip "!{output_name}_merged.regenie"
    '''
}
