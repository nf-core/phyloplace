/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*** REMOVED DURING TEMPLATE UPDATE ***/
//  include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'
//
//  def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
//  def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
//  def summary_params = paramsSummaryMap(workflow)
//
//  // Print parameter summary log to screen
//  log.info logo + paramsSummaryLog(workflow) + citation
//
//  WorkflowPhyloplace.initialise(params, log)
//
//  // Check input path parameters to see if they exist
//  def checkPathParamList = [ params.input ]
//  for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
//
//  // Check mandatory parameters
//  if (params.input) {
//      Channel.fromPath(params.input)
//          .splitCsv(header: true)
//          .map {
//              [
//                  meta: [ id: it.sample ],
//                  data: [
//                      alignmethod:  it.alignmethod ? it.alignmethod    : 'hmmer',
//                      queryseqfile: file(it.queryseqfile),
//                      refseqfile:   file(it.refseqfile),
//                      hmmfile:      it.hmmfile     ? file(it.hmmfile,  checkIfExists: true) : [],
//                      refphylogeny: file(it.refphylogeny),
//                      model:        it.model,
//                      taxonomy:     it.taxonomy    ? file(it.taxonomy, checkIfExists: true) : []
//                  ]
//              ]
//          }
//          .set { ch_pp_data }
//  } else if ( params.id && params.queryseqfile && params.refseqfile && params.refphylogeny && params.model ) {
//      ch_pp_data = Channel.of([
//          meta: [ id: params.id ],
//          data: [
//              alignmethod:  params.alignmethod ? params.alignmethod    : 'hmmer',
//              queryseqfile: file(params.queryseqfile),
//              refseqfile:   file(params.refseqfile),
//              hmmfile:      params.hmmfile     ? file(params.hmmfile)  : [],
//              refphylogeny: file(params.refphylogeny),
//              model:        params.model,
//              taxonomy:     params.taxonomy    ? file(params.taxonomy) : []
//          ]
//      ])
//  } else {
//      exit 1, "You must specify either an input sample  sheet with --input or a full set of --id, --queryseqfile, --refseqfile, --refphylogeny and --model arguments (all have defaults except --model)"
//  }
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTA_NEWICK_EPANG_GAPPA } from '../subworkflows/nf-core/fasta_newick_epang_gappa/main'
include { MULTIQC                  } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap         } from 'plugin/nf-validation'
include { paramsSummaryMultiqc     } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText   } from '../subworkflows/local/utils_nfcore_phyloplace_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PHYLOPLACE {

    take:
    ch_pp_data // channel: data parsed from --input file or cli params

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: Run phylogenetic placement
    //
    FASTA_NEWICK_EPANG_GAPPA ( ch_pp_data )
    ch_versions = ch_versions.mix(FASTA_NEWICK_EPANG_GAPPA.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
