//
// Subworkflow with functionality specific to the nf-core/phyloplace pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFVALIDATION_PLUGIN } from '../../nf-core/utils_nfvalidation_plugin'
include { paramsSummaryMap          } from 'plugin/nf-validation'
include { fromSamplesheet           } from 'plugin/nf-validation'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { dashedLine                } from '../../nf-core/utils_nfcore_pipeline'
include { nfCoreLogo                } from '../../nf-core/utils_nfcore_pipeline'
include { imNotification            } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { workflowCitation          } from '../../nf-core/utils_nfcore_pipeline'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    help              // boolean: Display help text
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    phyloplace_input  //  string: Path to phyloplace input samplesheet
    phylosearch_input //  string: Path to phylosearch input samplesheet

    main:

    ch_versions = Channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    //
    // Validate parameters and generate parameter summary to stdout
    //
    pre_help_text = nfCoreLogo(monochrome_logs)
    post_help_text = '\n' + workflowCitation() + '\n' + dashedLine(monochrome_logs)
    def String workflow_command = "nextflow run ${workflow.manifest.name} -profile <docker/singularity/.../institute> <--phyloplace_input phyloplace.csv/--phylosearch_input phylosearch.csv> --outdir <OUTDIR>"
    UTILS_NFVALIDATION_PLUGIN (
        help,
        workflow_command,
        pre_help_text,
        post_help_text,
        validate_params,
        "nextflow_schema.json"
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE (
        nextflow_cli_args
    )
    //
    // Custom validation for pipeline parameters
    //
    validateInputParameters()

    //
    // If provided, create channel from either of the two types of input file provided through params.phyloplace_input or params.phylosearch_input
    //

    // Check mandatory parameters and construct the input channel for the pipeline
    ch_phylosearch_data = Channel.empty()
    ch_sequence_fasta   = Channel.empty()
    ch_phyloplace_data  = Channel.empty()

    if ( params.phylosearch_input && params.search_fasta ) {
        ch_phylosearch_data = Channel.fromPath(params.phylosearch_input)
            .splitCsv(header: true)
            .map {
                [
                    meta: [
                        id: it.target,
                        min_bitscore: it.min_bitscore
                    ],
                    data: [
                        alignmethod:    it.alignmethod  ? it.alignmethod                             : 'hmmer',
                        hmm:            file(it.hmm,  checkIfExists: true),
                        extract_hmm:    it.extract_hmm,
                        refseqfile:     it.refseqfile   ? file(it.refseqfile,   checkIfExists: true) : [],
                        refphylogeny:   it.refphylogeny ? file(it.refphylogeny, checkIfExists: true) : [],
                        model:          it.model,
                        taxonomy:       it.taxonomy     ? file(it.taxonomy,     checkIfExists: true) : []
                    ]
                ]
            }
        Channel.fromPath(params.search_fasta)
            .set { ch_sequence_fasta }
    } else if ( params.phyloplace_input ) {
        ch_phyloplace_data = Channel.fromPath(params.phyloplace_input)
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
    } else if ( params.phylosearch_input || params.fasta ) {
        exit 1, "For phylosearch mode, you need to provide an input sample sheet with --phylosearch_input *and* a fasta file with --search_fasta"
    } else {
        exit 1, "For phyloplace mode, you need to provide an input sample sheet with --phyloplace_input or the corresponding info with individual parameters"
    }

    emit:
    phyloplace_data  = ch_phyloplace_data
    phylosearch_data = ch_phylosearch_data
    sequence_fasta   = ch_sequence_fasta
    versions         = ch_versions
}

/*
========================================================================================
    SUBWORKFLOW FOR PIPELINE COMPLETION
========================================================================================
*/

workflow PIPELINE_COMPLETION {

    take:
    email           //  string: email address
    email_on_fail   //  string: email address sent on pipeline failure
    plaintext_email // boolean: Send plain-text email instead of HTML
    outdir          //    path: Path to output directory where results will be published
    monochrome_logs // boolean: Disable ANSI colour codes in log output
    hook_url        //  string: hook URL for notifications
    multiqc_report  //  string: Path to MultiQC report

    main:

    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")

    //
    // Completion email and summary
    //
    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
                multiqc_report.toList()
            )
        }

        completionSummary(monochrome_logs)

        if (hook_url) {
            imNotification(summary_params, hook_url)
        }
    }

    workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting"
    }
}

/*
========================================================================================
    FUNCTIONS
========================================================================================
*/
//
// Check and validate pipeline parameters
//
def validateInputParameters() {
    genomeExistsError()
}

//
// Validate channels from input samplesheet
//
def validateInputSamplesheet(input) {
    def (metas, fastqs) = input[1..2]

    // Check that multiple runs of the same sample are of the same datatype i.e. single-end / paired-end
    def endedness_ok = metas.collect{ it.single_end }.unique().size == 1
    if (!endedness_ok) {
        error("Please check input samplesheet -> Multiple runs of a sample must be of the same datatype i.e. single-end or paired-end: ${metas[0].id}")
    }

    return [ metas[0], fastqs ]
}
//
// Get attribute from genome config file e.g. fasta
//
def getGenomeAttribute(attribute) {
    if (params.genomes && params.genome && params.genomes.containsKey(params.genome)) {
        if (params.genomes[ params.genome ].containsKey(attribute)) {
            return params.genomes[ params.genome ][ attribute ]
        }
    }
    return null
}

//
// Exit pipeline if incorrect --genome key provided
//
def genomeExistsError() {
    if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
        def error_string = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
            "  Genome '${params.genome}' not found in any config files provided to the pipeline.\n" +
            "  Currently, the available genome keys are:\n" +
            "  ${params.genomes.keySet().join(", ")}\n" +
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        error(error_string)
    }
}

//
// Generate methods description for MultiQC
//
def toolCitationText() {
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "Tool (Foo et al. 2023)" : "",
    // Uncomment function in methodsDescriptionText to render in MultiQC report
    def citation_text = [
            "Tools used in the workflow included:",
            "HMMER (Eddy 2011)",
            "MAFFT (Katoh et al. 2002)",
            "EPA-NG (Barbera et al. 2019)",
            "Gappa (Czech et al. 2020)",
            "MultiQC (Ewels et al. 2016)",
            "."
        ].join(' ').trim()

    return citation_text
}

def toolBibliographyText() {
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "<li>Author (2023) Pub name, Journal, DOI</li>" : "",
    // Uncomment function in methodsDescriptionText to render in MultiQC report
    def reference_text = [
            "<li>Eddy, Sean R. “Accelerated Profile HMM Searches.” PLoS Comput Biol 7, no. 10 (October 20, 2011): e1002195. https://doi.org/10.1371/journal.pcbi.1002195.</li>",
            "<li>Katoh, Kazutaka, Kazuharu Misawa, Kei‐ichi Kuma, and Takashi Miyata. “MAFFT: A Novel Method for Rapid Multiple Sequence Alignment Based on Fast Fourier Transform.” Nucleic Acids Research 30, no. 14 (July 15, 2002): 3059–66. https://doi.org/10.1093/nar/gkf436.</li>",
            "<li>Barbera, Pierre, Alexey M Kozlov, Lucas Czech, Benoit Morel, Diego Darriba, Tomáš Flouri, and Alexandros Stamatakis. “EPA-Ng: Massively Parallel Evolutionary Placement of Genetic Sequences.” Systematic Biology 68, no. 2 (March 1, 2019): 365–69. https://doi.org/10.1093/sysbio/syy054.</li>",
            "<li>Czech, Lucas, Pierre Barbera, and Alexandros Stamatakis. “Genesis and Gappa: Processing, Analyzing and Visualizing Phylogenetic (Placement) Data.” Bioinformatics 36, no. 10 (May 1, 2020): 3263–65. https://doi.org/10.1093/bioinformatics/btaa070.</li>",
            "<li>Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics , 32(19), 3047–3048. doi: /10.1093/bioinformatics/btw354</li>"
        ].join(' ').trim()

    return reference_text
}

def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named map so can be used as with familar NXF ${workflow} variable syntax in the MultiQC YML file
    def meta = [:]
    meta.workflow = workflow.toMap()
    meta["manifest_map"] = workflow.manifest.toMap()

    // Pipeline DOI
    if (meta.manifest_map.doi) {
        // Using a loop to handle multiple DOIs
        // Removing `https://doi.org/` to handle pipelines using DOIs vs DOI resolvers
        // Removing ` ` since the manifest.doi is a string and not a proper list
        def temp_doi_ref = ""
        String[] manifest_doi = meta.manifest_map.doi.tokenize(",")
        for (String doi_ref: manifest_doi) temp_doi_ref += "(doi: <a href=\'https://doi.org/${doi_ref.replace("https://doi.org/", "").replace(" ", "")}\'>${doi_ref.replace("https://doi.org/", "").replace(" ", "")}</a>), "
        meta["doi_text"] = temp_doi_ref.substring(0, temp_doi_ref.length() - 2)
    } else meta["doi_text"] = ""
    meta["nodoi_text"] = meta.manifest_map.doi ? "" : "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

    // Tool references
    meta["tool_citations"] = ""
    meta["tool_bibliography"] = ""

    meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    meta["tool_bibliography"] = toolBibliographyText()


    def methods_text = mqc_methods_yaml.text

    def engine =  new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}
