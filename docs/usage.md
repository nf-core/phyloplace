# nf-core/phyloplace: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/phyloplace/usage](https://nf-co.re/phyloplace/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

This pipeline performs "phylogenetic placement" of query sequences on to a reference phylogeny, or sequence search followed by phylogenetic placement.
With this method, the likelihoods of placing query sequences in the reference phylogeny are calculated on a one-by-one basis.
This means that a full phylogeny is not estimated, which is perfect e.g. when sequences come from PCR amplicons or are fragments from metagenomes, but also when the number of query sequences is very large.
One of the outputs from the pipeline is nevertheless a full phylogeny containing both query and reference sequences, but this is produced by grafting the query sequences on to the reference phylogeny in their most likely positions.

Placement is performed with the [EPA-NG](https://github.com/Pbdas/epa-ng/blob/master/README.md) program after query sequences have been aligned to the reference alignment.

The pipeline can either take parameters on the command line (or in a `params.yaml` file, see below) to perform a single placement, or a sample `csv` file that can accomodate parameters for several placements.
There are two different types of sample `csv` files, one for direct phylogenetic placement (`--phyloplace_input`), the other for search followed by phylogenetic placement (`--phylosearch_input`).

## Parameter input

At minimum, four parameters are required:

1. `--queryseqfile`: A fasta formatted file with sequences to place.
2. `--refseqfile`: Reference sequences, several popular formats supported e.g. aligned fasta and phylip. Unless when specifying an `--hmmfile`, the sequences needs to be aligned.
3. `--refphylogeny`: Reference phylogeny.
4. `--model`: Evolutionary model used when estimating the phylogeny, e.g. "LG+F+R6".

## Samplesheet input for phylogenetic placement

Each of the four parameters mentioned above can be specified as columns in a comma separated sample sheet instead.
In addition, a `sample` column needs to be present.

```bash
--phyloplace_input '[path to samplesheet file]'
```

```csv title="phyloplace_sheet.csv"
sample,queryseqfile,refseqfile,refphylogeny,model
pp0,q0.faa,ref0.alnfaa,ref0.newick,LG
pp1,q1.faa,ref1.alnfaa,ref1.newick,LG+F+R6
```

## Samplesheet input for search followed by phylogenetic placement

This mode of the pipeline starts by searching a fasta file with a set of HMMER `hmm` files.
The results are then passed to phylogenetic placement.
The samplesheet for this mode hence needs to contain paths to `hmm` files plus the phylogenetic placement information.
(_Note_: If an `hmm` file is not accompanied by a reference tree, plus the associated information, this will be used to search, but not phylogenetic placement, and the sequences will appear in a result table.
In the below example, the `rnr` entry will only be used for searching, while the other two will be both searched for and placed.)
The rest of the sample sheet is like the one for phylogenetic placement only.

In addition to the sample sheet, this mode requires that a fasta file to search is provided via the `--search_fasta` parameter.

```bash
--phylosearch_input '[path to samplesheet file]' --search_fasta '[path to fasta file]'
```

```csv title="phylosearch_sheet.csv"
target,hmm,refseqfile,refphylogeny,model,taxonomy
ring-hydrox,PF00848.hmm,PF00848.alnfaa,PF00848.newick,LG+F+I,PF00848.taxonomy.tsv
meth-dehydr,PF00389.hmm,PF00389.alnfaa,PF00389.newick,LG+F+I,PF00848.taxonomy.tsv
rnr,PF00788.hmm,,,,
```

## Running the pipeline

Run the pipeline with command line parameters specifying the placement parameters as follows:

```bash
nextflow run nf-core/phyloplace --refphylogeny reference.newick --refseqfile reference.alnfaa --query query.faa --model LG+F --taxonomy taxonomy.tsv -profile docker
```

With a placement samplesheet as follows:

```bash
nextflow run nf-core/phyloplace --phyloplace_input phyloplace_sheet.csv -profile docker
```

Or in search and place mode as follows:

```bash
nextflow run nf-core/phyloplace --phylosearch_input phylosearch_sheet.csv --search_fasta unknowns.faa -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/phyloplace -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
phyloplace_input: './phylosearch_sheet.csv'
outdir: './results/'
search_fasta: './unknowns.faa'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/phyloplace
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/phyloplace releases page](https://github.com/nf-core/phyloplace/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
