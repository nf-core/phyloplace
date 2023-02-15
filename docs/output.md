# nf-core/phyloplace: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Alignment](#alignment) - Align query sequences to the reference alignment
- [Placement](#placement) - Place query sequences in the reference phylogeny
- [Summary](#summary) - Summarise placement with a grafted tree, a classification and a heattree
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### Alignment

Alignment of query sequences is done either with [HMMER](http://hmmer.org/) or [MAFFT](https://mafft.cbrc.jp/alignment/software/).

#### HMMER

When using HMMER as the alignment program, a profile is first built, which is then used to align _both_ the query and reference sequences, hence the presence of alignment files for the reference sequences in the output.
The realignment of the reference sequences is done because an alignment will likely result in a profile that doesn't exactly reflect the structure of the alignment in all parts.
In particular, gappy positions in the original alignment will typically not be covered by the profile.
These positions are often not phylogenetically informative or reliable.
The MAFFT alignment strategy keeps the structure of the original reference alignment.

<details markdown="1">
<summary>Output files</summary>

- `hmmer/`
  - `*.query.hmmalign.sthlm.gz`: Query sequences aligned to reference HMM, in [Stockholm format](https://sonnhammer.sbc.su.se/Stockholm.html).
  - `*.query.hmmalign.masked.sthlm.gz`: Masked query sequence alignment, in Stockholm format.
  - `*.query.hmmalign.masked.afa.gz`: Masked query sequence alignment, in Fasta format.
  - `*.ref.hmmalign.sthlm.gz`: Reference sequences aligned to reference HMM, in [Stockholm format](https://sonnhammer.sbc.su.se/Stockholm.html).
  - `*.ref.hmmalign.masked.sthlm.gz`: Masked query sequence alignment, in Stockholm format.
  - `*.ref.hmmalign.masked.afa.gz`: Masked query sequence alignment, in Fasta format.
  - `*.ref.hmmbuild.txt`: Log from HMM profile build.
  - `*.ref.hmm.gz`: HMM profile made from the reference alignment, if not provided using the `hmmfile` parameter.
  - `*.ref.unaligned.afa.gz`: "Unaligned", i.e. without gap characters, reference sequences in Fasta format.

</details>

#### MAFFT

When MAFFT is used for alignment, it us run with the `--keeplength` option to ensure the structure of the query alignment is identical to the reference alignment.
Since the resulting alignment contains both query and reference sequences it needs to be split, which is done with EPA-NG which places two files in the `epang` directory.

<details markdown="1">
<summary>Output files</summary>

- `mafft/`
  - `*.fas`: Full alignment, containing both reference and query sequences.
- `epang/`
  - `*.query.fasta.gz`: Aligned query sequences in Fasta format.
  - `*.reference.fasta.gz`: Aligned query sequences in Fasta format.

</details>

### Placement

Phylogenetic placement of query sequences is performed with [EPA-NG](https://github.com/Pbdas/epa-ng).

<details markdown="1">
<summary>Output files</summary>

- `epang/`
  - `*.epa_info.log`: Log file from phylogenetic placement with EPA-NG.
  - `*.epa_result.jplace.gz`: Main result file from EPA-NG in jplace format.

</details>

### Summary

A number of summary operations are performed with [Gappa](https://github.com/lczech/gappa) after placement.
First, the query sequences are grafted on to the reference tree to produce a comprehensive tree containing all sequences.
Second, the "heattree" function is called which produces phylogenies in different formats with branches coloured to indicate the number of placed sequences in various parts of the tree.
Third, if the user provides a classification of the reference sequences, a classification of query sequences is performed.

<details markdown="1">
<summary>Output files</summary>

- `gappa/`
  - `*.graft.*.newick`: Full phylogeny with query sequences grafted on to the reference phylogeny.
  - `*.heattree.*`: Files from calling `gappa examine heattree`, see [Gappa documentation](https://github.com/Pbdas/epa-ng/blob/master/README.md) for details.
  - `*.taxonomy.*`: Classification files from calling `gappa examine examinassign`, see [Gappa documentation](https://github.com/Pbdas/epa-ng/blob/master/README.md) for details.

</details>

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
