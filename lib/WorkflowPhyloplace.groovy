//
// This file holds several functions specific to the workflow/phyloplace.nf in the nf-core/phyloplace pipeline
//

import nextflow.Nextflow
import groovy.text.SimpleTemplateEngine

class WorkflowPhyloplace {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {

        genomeExistsError(params, log)
    }

    //
    // Get workflow summary for MultiQC
    //
    public static String paramsSummaryMultiqc(workflow, summary) {
        String summary_section = ''
        for (group in summary.keySet()) {
            def group_params = summary.get(group)  // This gets the parameters of that particular group
            if (group_params) {
                summary_section += "    <p style=\"font-size:110%\"><b>$group</b></p>\n"
                summary_section += "    <dl class=\"dl-horizontal\">\n"
                for (param in group_params.keySet()) {
                    summary_section += "        <dt>$param</dt><dd><samp>${group_params.get(param) ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>\n"
                }
                summary_section += "    </dl>\n"
            }
        }

        String yaml_file_text  = "id: '${workflow.manifest.name.replace('/','-')}-summary'\n"
        yaml_file_text        += "description: ' - this information is collected when the pipeline is started.'\n"
        yaml_file_text        += "section_name: '${workflow.manifest.name} Workflow Summary'\n"
        yaml_file_text        += "section_href: 'https://github.com/${workflow.manifest.name}'\n"
        yaml_file_text        += "plot_type: 'html'\n"
        yaml_file_text        += "data: |\n"
        yaml_file_text        += "${summary_section}"
        return yaml_file_text
    }

    //
    // Generate methods description for MultiQC
    //

    public static String toolCitationText(params) {

        // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "Tool (Foo et al. 2023)" : "",
        // Uncomment function in methodsDescriptionText to render in MultiQC report
        def citation_text = [
                "Tools used in the workflow included:",
                "EPA-ng (Barbera et al. 2019)",
                "Gappa (Czech et al. 2020)",
                params["alignmethod"] == "hmmer" ? "HMMER (Eddy 2011)" : "",
                params["alignmethod"] == "mafft" ? "MAFFT (Katoh et al. 2002)" : "",
                "MultiQC (Ewels et al. 2016)",
                "."
            ].join(' ').trim()

        return citation_text
    }

    public static String toolBibliographyText(params) {

        // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "<li>Author (2023) Pub name, Journal, DOI</li>" : "",
        // Uncomment function in methodsDescriptionText to render in MultiQC report
        def reference_text = [
                "<li>Barbera, Pierre, Alexey M Kozlov, Lucas Czech, Benoit Morel, Diego Darriba, Tomáš Flouri, and Alexandros Stamatakis. 2019. “EPA-Ng: Massively Parallel Evolutionary Placement of Genetic Sequences.” Systematic Biology 68 (2): 365–69. https://doi.org/10.1093/sysbio/syy054.</li>",
                "<li>Czech, Lucas, Pierre Barbera, and Alexandros Stamatakis. 2020. “Genesis and Gappa: Processing, Analyzing and Visualizing Phylogenetic (Placement) Data.” Bioinformatics 36 (10): 3263–65. https://doi.org/10.1093/bioinformatics/btaa070.</li>",
                params["alignmethod"] == "hmmer" ? "<li>Eddy, Sean R. 2011. “Accelerated Profile HMM Searches.” PLoS Comput Biol 7 (10): e1002195. https://doi.org/10.1371/journal.pcbi.1002195.</li>" : "",
                params["alignmethod"] == "mafft" ? "<li>Katoh, Kazutaka, Kazuharu Misawa, Kei‐ichi Kuma, and Takashi Miyata. 2002. “MAFFT: A Novel Method for Rapid Multiple Sequence Alignment Based on Fast Fourier Transform.” Nucleic Acids Research 30 (14): 3059–66. https://doi.org/10.1093/nar/gkf436.</li>" : "",
                "<li>Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics , 32(19), 3047–3048. doi: /10.1093/bioinformatics/btw354</li>"
            ].join(' ').trim()

        return reference_text
    }

    public static String methodsDescriptionText(run_workflow, mqc_methods_yaml, params) {
        // Convert  to a named map so can be used as with familar NXF ${workflow} variable syntax in the MultiQC YML file
        def meta = [:]
        meta.workflow = run_workflow.toMap()
        meta["manifest_map"] = run_workflow.manifest.toMap()

        // Pipeline DOI
        meta["doi_text"] = meta.manifest_map.doi ? "(doi: <a href=\'https://doi.org/${meta.manifest_map.doi}\'>${meta.manifest_map.doi}</a>)" : ""
        meta["nodoi_text"] = meta.manifest_map.doi ? "": "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

        // Tool references
        meta["tool_citations"] = ""
        meta["tool_bibliography"] = ""

        meta["tool_citations"] = toolCitationText(params).replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
        meta["tool_bibliography"] = toolBibliographyText(params)
    }
}
