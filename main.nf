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

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_PHYLOPLACE {

    take:
    pp_data // channel: phyloplace data parsed from --input file or cli params

    main:

    //
    // WORKFLOW: Run pipeline
    //
    PHYLOPLACE (
        pp_data
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
    if (params.input) { 
        Channel.fromPath(params.input)
            .splitCsv(header: true)
            .map { 
                [ 
                    meta: [ id: it.sample ], 
                    data: [ 
                        alignmethod:  it.alignmethod ? it.alignmethod    : 'hmmer',
                        queryseqfile: file(it.queryseqfile),
                        refseqfile:   file(it.refseqfile),
                        hmmfile:      it.hmmfile     ? file(it.hmmfile,  checkIfExists: true) : [],
                        refphylogeny: file(it.refphylogeny),
                        model:        it.model,
                        taxonomy:     it.taxonomy    ? file(it.taxonomy, checkIfExists: true) : []
                    ] 
                ] 
            }
            .set { ch_pp_data }
    } else if ( params.id && params.queryseqfile && params.refseqfile && params.refphylogeny && params.model ) {
        Channel.of([
            meta: [ id: params.id ],
            data: [
                alignmethod:  params.alignmethod ? params.alignmethod    : 'hmmer',
                queryseqfile: file(params.queryseqfile),
                refseqfile:   file(params.refseqfile),
                hmmfile:      params.hmmfile     ? file(params.hmmfile)  : [],
                refphylogeny: file(params.refphylogeny),
                model:        params.model,
                taxonomy:     params.taxonomy    ? file(params.taxonomy) : []
            ]
        ])
            .set { ch_pp_data }
    } else {
        exit 1, "You must specify either an input sample  sheet with --input or a full set of --id, --queryseqfile, --refseqfile, --refphylogeny and --model arguments (all have defaults except --model)"
    }

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_PHYLOPLACE (
        ch_pp_data
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
