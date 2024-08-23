#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/phyloplace
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/phyloplace

    Website: https://nf-co.re/phyloplace
    Slack  : https://nfcore.slack.com/channels/phyloplace
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PHYLOPLACE              } from './workflows/phyloplace'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_phyloplace_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_phyloplace_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_PHYLOPLACE {

    take:
    phyloplace_data
    phylosearch_data
    sequence_fasta

    main:

    //
    // WORKFLOW: Run pipeline
    //
    PHYLOPLACE (
        phyloplace_data,
        phylosearch_data,
        sequence_fasta
    )

    emit:
    multiqc_report = PHYLOPLACE.out.multiqc_report // channel: /path/to/multiqc_report.html

}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.help,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir
    )

    // Check mandatory parameters and construct the input channel for the pipeline
    // (I'm not sure this belongs here after the 2.13 upgrade. I moved it from workflows/phyloplace.nf.)
    ch_phylosearch_data = Channel.empty()
    ch_sequence_fasta   = Channel.empty()
    ch_phyloplace_data  = Channel.empty()

    if ( params.input && params.search_fasta ) {
        Channel.fromPath(params.input)
            .splitCsv(header: true)
            .map {
                [
                    meta: [ id: it.target ],
                    data: [
                        alignmethod:    it.alignmethod  ? it.alignmethod                             : 'hmmer',
                        hmm:            file(it.hmm,  checkIfExists: true),
                        extract_hmm:    it.extract_hmm,
                        min_bitscore:   it.min_bitscore,
                        refseqfile:     it.refseqfile   ? file(it.refseqfile,   checkIfExists: true) : [],
                        refphylogeny:   it.refphylogeny ? file(it.refphylogeny, checkIfExists: true) : [],
                        model:          it.model,
                        taxonomy:       it.taxonomy     ? file(it.taxonomy,     checkIfExists: true) : []
                    ]
                ]
            }
            .set { ch_phylosearch_data }
        Channel.fromPath(params.search_fasta)
            .set { ch_sequence_fasta }
    } else if ( params.id && params.queryseqfile && params.refseqfile && params.refphylogeny && params.model ) {
        Channel.of([
            meta: [ id: params.id ],
            data: [
                alignmethod:  params.alignmethod ? params.alignmethod    : 'hmmer',
                queryseqfile: file(params.queryseqfile),
                refseqfile:   file(params.refseqfile),
                refphylogeny: file(params.refphylogeny),
                hmmfile:      params.hmmfile     ? file(params.hmmfile)  : [],
                model:        params.model,
                taxonomy:     params.taxonomy    ? file(params.taxonomy) : []
            ]
        ])
            .set { ch_phyloplace_data }
    } else if ( params.input || params.fasta ) {
        exit 1, "For phylosearch mode, you need to provide an input sample sheet with --input *and* a fasta file with --search_data"
    } else {
        exit 1, "For phyloplace mode, you can only specify parameters via command line parameters"
    }

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_PHYLOPLACE (
        ch_phyloplace_data,
        ch_phylosearch_data,
        ch_sequence_fasta
    )

    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        NFCORE_PHYLOPLACE.out.multiqc_report
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
