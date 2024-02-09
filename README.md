# ![nf-core/phyloplace](docs/images/nf-core-phyloplace_logo_light.png#gh-light-mode-only) ![nf-core/phyloplace](docs/images/nf-core-phyloplace_logo_dark.png#gh-dark-mode-only)

[![GitHub Actions CI Status](https://github.com/nf-core/phyloplace/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/phyloplace/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/phyloplace/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/phyloplace/actions?query=workflow%3A%22nf-core+linting%22)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/phyloplace/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.7643941-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.7643941)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/phyloplace)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23phyloplace-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/phyloplace)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/phyloplace** is a bioinformatics best-practice analysis pipeline that performs phylogenetic placement with EPA-NG.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner.
It uses Docker/Singularity containers making installation trivial and results highly reproducible.
The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies.
Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure.
This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources.The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/phyloplace/results).

## Pipeline summary

1. Align query sequences to the reference alignment using either [`HMMER`](http://hmmer.org/) or [`MAFFT`](https://mafft.cbrc.jp/alignment/software/).
2. Place query sequences in reference phylogeny with [`EPA-NG`](https://github.com/Pbdas/epa-ng).
3. Graft query sequences onto the reference phylogeny with [`GAPPA`](https://github.com/lczech/gappa).
4. If provided with a classification of the reference sequences, classify query sequences with [`GAPPA`](https://github.com/lczech/gappa).

<p align="center">
    <img src="docs/images/phyloplace_workflow.png" alt="nf-core/phyloplace workflow overview" width="60%">
</p>

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

Now, you can run the pipeline using:

```bash
nextflow run nf-core/phyloplace \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/phyloplace/usage) and the [parameter documentation](https://nf-co.re/phyloplace/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/phyloplace/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/phyloplace/output).

## Credits

nf-core/phyloplace was originally written by Daniel Lundin.

We thank the following people for their extensive assistance in the development of this pipeline:

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#phyloplace` channel](https://nfcore.slack.com/channels/phyloplace) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

If you use nf-core/phyloplace for your analysis, please cite it using the following doi: [10.5281/zenodo.7643941](https://doi.org/10.5281/zenodo.7643941)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
