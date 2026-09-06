/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { HMMER_HMMEXTRACT              } from '../modules/local/hmmer/hmmextract'
include { CUSTOM_RESOLVETAXONOMY        } from '../modules/nf-core/custom/resolvetaxonomy/main'
include { GAPPA_EDITMERGE               } from '../modules/nf-core/gappa/editmerge/main'
include { GAPPA_EXAMINEASSIGN    as GAPPA_JOINTASSIGN   } from '../modules/nf-core/gappa/examineassign/main'
include { GAPPA_EXAMINEGRAFT     as GAPPA_JOINTGRAFT    } from '../modules/nf-core/gappa/examinegraft/main'
include { GAPPA_EXAMINEHEATTREE  as GAPPA_JOINTHEATTREE } from '../modules/nf-core/gappa/examineheattree/main'
include { FASTA_HMMSEARCH_RANK_FASTAS   } from '../subworkflows/nf-core/fasta_hmmsearch_rank_fastas/main'
include { FASTA_NEWICK_EPANG_GAPPA      } from '../subworkflows/nf-core/fasta_newick_epang_gappa/main'
include { MULTIQC                       } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap              } from 'plugin/nf-schema'
include { paramsSummaryMultiqc          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText        } from '../subworkflows/local/utils_nfcore_phyloplace_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Re-indent every line of a block of text, for embedding as a YAML block literal (`data: |`)
// in a MultiQC custom content file: every content line must be indented at least as much as
// the block's first line, which raw multi-line tool log/SVG content won't be on its own.
//
def indentBlock(text, indent) {
    def pad = ' ' * indent
    text.readLines().collect { pad + it }.join('\n')
}

//
// Whether a reference sequence file is FASTA -- only FASTA headers have room for embedded
// taxonomy text (GTDB-style `>id taxonomy;string`), so this gates whether
// CUSTOM_RESOLVETAXONOMY is worth invoking on a given row at all.
//
def isFastaFile(path) {
    path.withReader { reader -> reader.readLine()?.trim()?.startsWith('>') } ?: false
}

//
// Wrap a GAPPA heat tree SVG in a MultiQC custom content file. Reference trees with many
// tips can produce very large SVGs; skip embedding (rather than bloating the report) above
// this size and just point at the real output file.
//
def heattreeMqc(name, svg_file, section, description) {
    def max_svg_bytes = 1_048_576
    def size = svg_file.size()
    def content = size <= max_svg_bytes
        ? indentBlock(svg_file.text.replaceFirst(/^<\?xml[^>]*\?>\s*/, ''), 2)
        : "  <p>Heat tree too large to embed (${(size / (1024 * 1024)).round(1)} MiB) &mdash; see <code>gappa/${svg_file.name}</code> in the pipeline output.</p>"
    [
        "${name}.heattree_mqc.yaml",
        """id: 'heattree_${name}'
section_name: '${section}'
description: '${description}'
plot_type: 'html'
data: |
${content}
"""
    ]
}

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
    save_domtblout      // boolean: also save hmmsearch's per-domain hit table (--domtblout)
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
        .filter { it -> it.data.extract_hmm }
        .map { it -> [ it.meta, it.data.hmm, it.data.extract_hmm ] }
        .set { ch_hmmextract }

    HMMER_HMMEXTRACT(ch_hmmextract)

    // Create an input channel for FASTA_HMMSEARCH_RANK_FASTAS by adding the non-keyed entries from the original channel to the output of the extracted
    HMMER_HMMEXTRACT.out.hmm
        .mix(
            ch_phylosearch_data
                .filter { it -> ! it.data.extract_hmm }
                .map { it -> [ it.meta, it.data.hmm ] }
        )
        .set { ch_search_profiles }

    FASTA_HMMSEARCH_RANK_FASTAS(ch_search_profiles, ch_sequence_fasta, save_domtblout)

    ch_phyloplace_data = FASTA_HMMSEARCH_RANK_FASTAS.out.seqfastas
        .join(
            ch_phylosearch_data
                .filter { it -> it.data.alignmethod && it.data.refseqfile && it.data.refphylogeny }
                .map { it -> [ [ id: it.meta.id ], it ] }
        )
        // Carry the search row over wholesale, overriding only the query sequences the search
        // produced. Listing the fields out instead silently drops any column added to the sample
        // sheet later, since nothing checks that the two lists agree.
        .map { _id, queryseqfile, row -> [
            meta: row.meta,
            data: row.data + [ queryseqfile: queryseqfile ]
        ] }
        .mix(ch_phyloplace_data)

    // Compare what the sample sheet declared, not what CUSTOM_RESOLVETAXONOMY resolves: rows
    // deriving taxonomy from identical reference sequences each get their own resolved file,
    // equal in content but not in path, and the group check below would reject them.
    def ch_declared_taxonomy = ch_phyloplace_data
        .map { row -> [ row.meta.id, row.data.taxonomy ? row.data.taxonomy.toString() : '' ] }

    //
    // MODULE: Derive taxonomy from refseqfile's own FASTA headers (GTDB-style
    // `>id taxonomy;string`) when no --taxonomy file was given, instead of just
    // proceeding without any taxonomic classification. Only applies when refseqfile
    // is itself FASTA -- other HMMER-supported formats have no room for embedded
    // taxonomy text and are passed through unchanged. Headers are stripped down to a
    // bare id regardless, since some downstream tools (EPA-NG, GAPPA) keep the whole
    // header line as the leaf name rather than just the first token.
    //
    ch_phyloplace_data
        .branch { row ->
            fasta: isFastaFile(row.data.refseqfile)
            other: true
        }
        .set { ch_pp_by_format }

    CUSTOM_RESOLVETAXONOMY(
        ch_pp_by_format.fasta.map { row -> [ row.meta, row.data.taxonomy ?: [], row.data.refseqfile, false ] }
    )

    // --taxonomy is fully optional, so an empty resolved file (no embedded text
    // found anywhere, same as no --taxonomy given at all) means "no taxonomy" --
    // reset it to `[]` to keep GAPPA_ASSIGN's own ext.when skip working, rather than
    // handing it a real-but-empty file it would otherwise try (and fail) to use.
    CUSTOM_RESOLVETAXONOMY.out.warnings.subscribe { _meta, warnings_file ->
        def text = warnings_file.text.trim()
        if (text) log.warn(text)
    }

    ch_pp_by_format.fasta
        .map { row -> [ [ id: row.meta.id ], row ] }
        .join(CUSTOM_RESOLVETAXONOMY.out.taxonomy.map { meta, tax -> [ [ id: meta.id ], tax ] })
        .join(CUSTOM_RESOLVETAXONOMY.out.sequences.map { meta, seq -> [ [ id: meta.id ], seq ] })
        .map { _id, row, tax, seq -> [
            meta: row.meta,
            data: row.data + [
                refseqfile: seq,
                taxonomy: tax.isEmpty() ? [] : tax,
            ]
        ] }
        .mix(ch_pp_by_format.other)
        .set { ch_phyloplace_data }

    //
    // SUBWORKFLOW: Run phylogenetic placement
    //
    FASTA_NEWICK_EPANG_GAPPA(ch_phyloplace_data)

    //
    // MODULES: Summarise placements per reference tree, on top of the per-row summaries
    // above. `gappa examine assign` and `heat-tree` merge several jplace files themselves,
    // but `graft` does not, so the group is merged first and all three run off the merged
    // file. Single-row groups are dropped; their joint output would only repeat the per-row one.
    //
    def ch_reftree_groups = ch_phyloplace_data
        .filter { row -> row.data.reftreename }
        .map { row -> [ row.meta.id, row ] }
        .join(FASTA_NEWICK_EPANG_GAPPA.out.jplace.map { meta, jplace -> [ meta.id, jplace ] })
        .join(ch_declared_taxonomy)
        .map { id, row, jplace, declared_taxonomy -> [
            row.data.reftreename,
            [ id: id, jplace: jplace, taxonomy: row.data.taxonomy, declared_taxonomy: declared_taxonomy ]
        ] }
        .groupTuple()
        .filter { _reftreename, rows -> rows.size() > 1 }
        .map { reftreename, rows ->
            // `gappa examine assign` takes a single --taxon-file, so the group has to agree
            // on one. Stop rather than pick: classifying the whole group by whichever row
            // came first is a wrong answer, not a smaller problem.
            if (rows.collect { r -> r.declared_taxonomy }.unique().size() > 1) {
                error(
                    "Rows grouped under reftreename '${reftreename}' declare different taxonomy files, " +
                    "but one joint classification can only use one of them: " +
                    rows.collect { r -> "${r.id} -> ${r.declared_taxonomy ?: '<none>'}" }.sort().join(', ') + '.'
                )
            }
            [ [ id: reftreename ], rows.collect { r -> r.jplace }, rows.find { r -> r.taxonomy }?.taxonomy ?: [] ]
        }

    GAPPA_EDITMERGE ( ch_reftree_groups.map { meta, jplaces, _taxonomy -> [ meta, jplaces ] } )

    GAPPA_JOINTGRAFT ( GAPPA_EDITMERGE.out.jplace )

    GAPPA_JOINTASSIGN (
        GAPPA_EDITMERGE.out.jplace
            .join(ch_reftree_groups.map { meta, _jplaces, taxonomy -> [ meta, taxonomy ] })
    )

    GAPPA_JOINTHEATTREE ( GAPPA_EDITMERGE.out.jplace )

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
    // hmmbuild's and EPA-NG's own logs are plain text starting with '#'/free-text lines that
    // MultiQC's custom content module would otherwise try (and fail) to parse as a YAML header,
    // so wrap each in a small self-describing custom content yaml instead.
    def ch_hmmbuild_mqc = FASTA_NEWICK_EPANG_GAPPA.out.hmmbuild_log
        .collectFile { log_file ->
            def id = log_file.baseName - '.hmmbuild'
            def escaped = log_file.text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            [
                "${id}.hmmbuild_mqc.yaml",
                """id: 'hmmbuild_${id}'
section_name: 'HMMER hmmbuild: ${id}'
description: 'Profile HMM construction log from hmmbuild, run when no --hmmfile is provided for the hmmer alignment method.'
plot_type: 'html'
data: |
${indentBlock("<pre>${escaped}</pre>", 2)}
"""
            ]
        }
    def ch_epang_mqc = FASTA_NEWICK_EPANG_GAPPA.out.epang_log
        .collectFile { log_file ->
            def id = log_file.baseName - '.epa_info'
            def escaped = log_file.text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            [
                "${id}.epang_mqc.yaml",
                """id: 'epang_${id}'
section_name: 'EPA-NG placement: ${id}'
description: 'Phylogenetic placement run log from EPA-NG.'
plot_type: 'html'
data: |
${indentBlock("<pre>${escaped}</pre>", 2)}
"""
            ]
        }
    def ch_heattree_mqc = FASTA_NEWICK_EPANG_GAPPA.out.heattree
        .collectFile { meta, svg_file ->
            heattreeMqc(
                meta.id,
                svg_file,
                "GAPPA heat tree: ${meta.id}",
                'Placement density heat tree, showing where in the reference phylogeny most query sequences were placed.'
            )
        }
        .mix(
            GAPPA_JOINTHEATTREE.out.svg.collectFile { meta, svg_file ->
                heattreeMqc(
                    "joint_${meta.id}",
                    svg_file,
                    "GAPPA heat tree, reference tree ${meta.id}",
                    "Placement density heat tree over the placements of every profile sharing the reference tree ${meta.id}, taken together."
                )
            }
        )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(ch_hmmbuild_mqc)
    ch_multiqc_files = ch_multiqc_files.mix(ch_epang_mqc)
    ch_multiqc_files = ch_multiqc_files.mix(ch_heattree_mqc)
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
