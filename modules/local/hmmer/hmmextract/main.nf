// This is a modified version of nf-core/hmmer/hmmfetch that only extracts, but
// does so from a single input channel to keep things synchronized.
process HMMER_HMMEXTRACT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmmer:3.3.2--h87f3376_2':
        'biocontainers/hmmer:3.3.2--h87f3376_2' }"

    input:
    tuple val(meta), path(hmm), val(key)

    output:
    tuple val(meta), path("*.hmm"), emit: hmm
    tuple val("${task.process}"), val('hmmsearch'), eval("hmmsearch -h | grep -o '^# HMMER [0-9.]*' | sed 's/^# HMMER *//'"), emit: versions_hmmsearch, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def outfile = ! key ? '' : "> ${prefix}.hmm"

    // Avoid accidentally overwriting the input hmm
    def move    = ""
    if ( "${prefix}.hmm" == "${hmm}" ) {
        move    = "mv ${hmm} ${prefix}.in.hmm"
        hmm     = "${prefix}.in.hmm"
    }

    """
    $move

    hmmfetch \\
        $args \\
        $hmm \\
        $key \\
        $outfile
    """

    stub:
    def prefix  = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.hmm
    """
}
