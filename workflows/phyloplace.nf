/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { HMMER_HMMEXTRACT              } from '../modules/local/hmmer/hmmextract'
include { FASTA_HMMSEARCH_RANK_FASTAS   } from '../subworkflows/nf-core/fasta_hmmsearch_rank_fastas/main'
include { FASTA_NEWICK_EPANG_GAPPA      } from '../subworkflows/nf-core/fasta_newick_epang_gappa/main'
include { MULTIQC                       } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap              } from 'plugin/nf-schema'
include { paramsSummaryMultiqc          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText        } from '../subworkflows/local/utils_nfcore_phyloplace_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PHYLOPLACE {

    take:
    ch_phyloplace_data  // channel: [ meta: [ id: string ], data: [ alignmethod: string, queryseqfile: fasta, refseqfile: fasta, refphylogeny: newick, hmmfile: hmm, model: string, taxonomy: tsv ] ]
    ch_phylosearch_data // channel: [ meta: [ id: string, min_bitscore: int ], data: [ alignmethod: string, hmm: file, extract_hmm: file, refseqfile: fasta, refphylogeny: newick, model: string, taxonomy: tsv ] ]
    ch_sequence_fasta   // channel: sequences to search
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()

    // 1. Deal with entries in the ch_phylosearch_data channel, i.e. search, then add to the ch_phyloplace_data channel

    // For search entries with a named hmm to extract, call extraction
    ch_phylosearch_data
        .filter { it.data.extract_hmm }
        .map { [ it.meta, it.data.hmm, it.data.extract_hmm ] }
        .set { ch_hmmextract }

    HMMER_HMMEXTRACT(ch_hmmextract)

    // Create an input channel for FASTA_HMMSEARCH_RANK_FASTAS by adding the non-keyed entries from the original channel to the output of the extracted
    HMMER_HMMEXTRACT.out.hmm
        .mix(
            ch_phylosearch_data
                .filter { ! it.data.extract_hmm }
                .map { [ it.meta, it.data.hmm ] }
        )
        .set { ch_search_profiles }

    FASTA_HMMSEARCH_RANK_FASTAS(ch_search_profiles, ch_sequence_fasta)

    ch_phyloplace_data = FASTA_HMMSEARCH_RANK_FASTAS.out.seqfastas
        .join(
            ch_phylosearch_data
                .filter { it.data.alignmethod && it.data.refseqfile && it.data.refphylogeny }
                .map { [ [ id: it.meta.id ], it ] }
        )
        .map { [
            meta: it[2].meta,
            data: [
                alignmethod: it[2].data.alignmethod,
                queryseqfile: it[1],
                refseqfile: it[2].data.refseqfile,
                refphylogeny: it[2].data.refphylogeny,
                model: it[2].data.model,
                taxonomy: it[2].data.taxonomy
            ]
        ] }
        .mix(ch_phyloplace_data)

    //
    // SUBWORKFLOW: Run phylogenetic placement
    //
    FASTA_NEWICK_EPANG_GAPPA(ch_phyloplace_data)

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'phyloplace_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'phyloplace'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )
    emit:multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
