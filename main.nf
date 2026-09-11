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

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PARAMS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Typed declarations for every param only ever read from within a script (this file,
    workflows/, subworkflows/local/). Params read directly inside nextflow.config itself --
    at config-parse time, before this file exists -- can't use this syntax and stay declared
    there instead (see the comment above that params block, and #74).
*/

params {
    // Input options
    phyloplace_input:             String? = null
    phylosearch_input:            String? = null
    id:                            String = 'placement'
    alignmethod:                   String = 'clustalo'
    queryseqfile:                 String? = null
    refseqfile:                   String? = null
    hmmfile:                      String? = null
    refphylogeny:                 String? = null
    model:                        String? = null
    taxonomy:                     String? = null
    search_fasta:                 String? = null
    save_domtblout:               Boolean = false

    // MultiQC options
    multiqc_config:               String? = null
    multiqc_title:                String? = null
    multiqc_logo:                 String? = null
    max_multiqc_email_size:        String = '25.MB'
    multiqc_methods_description:  String? = null

    // Boilerplate options
    email:                        String? = null
    email_on_fail:                String? = null
    plaintext_email:              Boolean = false
    monochrome_logs:              Boolean = false
    help_full:                    Boolean = false
    show_hidden:                  Boolean = false
    version:                      Boolean = false

    // Config options
    config_profile_name:          String? = null
    config_profile_description:   String? = null
    config_profile_contact:       String? = null
    config_profile_url:           String? = null

    // Schema validation default options
    validate_params:              Boolean = true
}

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
        sequence_fasta,
        params.save_domtblout,
        params.multiqc_config,
        params.multiqc_logo,
        params.multiqc_methods_description,
        params.outdir,
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
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.id,
        params.queryseqfile,
        params.refseqfile,
        params.refphylogeny,
        params.model,
        params.taxonomy,
        params.hmmfile,
        params.alignmethod,
        params.phyloplace_input,
        params.phylosearch_input,
        params.search_fasta,
        params.help,
        params.help_full,
        params.show_hidden,
    )


    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_PHYLOPLACE (
        PIPELINE_INITIALISATION.out.phyloplace_data,
        PIPELINE_INITIALISATION.out.phylosearch_data,
        PIPELINE_INITIALISATION.out.sequence_fasta
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
        NFCORE_PHYLOPLACE.out.multiqc_report
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
