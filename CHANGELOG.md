# nf-core/phyloplace: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.2.0dev - [yyyy-mm-dd]

### `Added`

    - [#79](https://github.com/nf-core/phyloplace/pull/79) - New optional `reftreename` sample sheet column, grouping rows that place onto the same reference tree so that the group is also grafted, classified and heat-treed as a whole, instead of only one profile at a time ([#78](https://github.com/nf-core/phyloplace/issues/78)) (by @erikrikarddaniel)
    - [#75](https://github.com/nf-core/phyloplace/pull/75) - Derive taxonomy from `--refseqfile` FASTA headers (GTDB single-file style) when `--taxonomy` is not given, instead of skipping taxonomic classification entirely ([#66](https://github.com/nf-core/phyloplace/issues/66)) (by @erikrikarddaniel)
    - [#72](https://github.com/nf-core/phyloplace/pull/72) - Alignment coordinates, lengths and coverage for each hit in the ranked `hmmsearch` summary, when `--save_domtblout` is set ([#70](https://github.com/nf-core/phyloplace/issues/70)) (by @erikrikarddaniel)
    - [#71](https://github.com/nf-core/phyloplace/pull/71) - New `--save_domtblout` option, saving hmmsearch's per-domain hit table in "search and place" mode ([#69](https://github.com/nf-core/phyloplace/issues/69)) (by @erikrikarddaniel)

### `Fixed`

    - [#71](https://github.com/nf-core/phyloplace/pull/71) - Correct the `hmmsearch` output files listed in the output documentation, where the human-readable table was listed as `*.tbl.gz` instead of `*.txt.gz` (by @erikrikarddaniel)

### `Changed`

    - [#81](https://github.com/nf-core/phyloplace/pull/81) - Update `gappa/examineassign`, `gappa/examinegraft` and `gappa/examineheattree` to gappa 0.9.0, so every gappa step runs the same version and container ([nf-core/modules#12858](https://github.com/nf-core/modules/pull/12858)) (by @erikrikarddaniel)
    - [#79](https://github.com/nf-core/phyloplace/pull/79) - Publish grafted trees as `<id>.graft.newick` instead of `<id>.graft.<id>.epa_result.newick`, dropping a repetition of the name and matching the new joint outputs (by @erikrikarddaniel)
    - [#77](https://github.com/nf-core/phyloplace/pull/77) - Adopt typed `params` blocks for pipeline-specific parameters, fixing boolean options (e.g. `--save_domtblout false`) that couldn't be turned off from the command line ([#74](https://github.com/nf-core/phyloplace/issues/74)) (by @erikrikarddaniel). Raises the minimum required Nextflow version to `26.04.0`.
    - [#73](https://github.com/nf-core/phyloplace/pull/73) - Update `seqtk/subseq` and `fasta_hmmsearch_rank_fastas` to fix output filenames glomming the input sequence filename onto the prefix ([nf-core/modules#12779](https://github.com/nf-core/modules/issues/12779)) (by @erikrikarddaniel)
    - [#68](https://github.com/nf-core/phyloplace/pull/68) - Template update to 4.1.0 (by @erikrikarddaniel)

### `Dependencies`

| software  | previously | now       |
| --------- | ---------- | --------- |
| gappa     | 0.8.0      | 0.9.0     |
| Nextflow  | >=25.10.4  | >=26.04.0 |
| nf-schema | 2.7.2      | 2.8.0     |

### `Deprecated`

## v2.1.0 - [2026-08-03]

### `Added`

    - [#63](https://github.com/nf-core/phyloplace/pull/63) - Report hmmbuild, EPA-NG and GAPPA heat tree logs/output in MultiQC ([#3](https://github.com/nf-core/phyloplace/issues/3)) (by @erikrikarddaniel)

### `Fixed`

### `Changed`

    - [#62](https://github.com/nf-core/phyloplace/pull/62) - Template update to 4.0.3 and software updates (by @erikrikarddaniel)

### `Dependencies`

### `Deprecated`

## v2.0.1 - [2026-06-16]

### `Added`

### `Fixed`

    - [#53](https://github.com/nf-core/phyloplace/pull/53) - Improve documentation of columns in input sheets [addresses #41](https://github.com/nf-core/phyloplace/issues/41) (by @erikrikarddaniel)
    - [#53](https://github.com/nf-core/phyloplace/pull/53) - Fix broken documentation links for parameters [addresses #49](https://github.com/nf-core/phyloplace/issues/49) (by @erikrikarddaniel)
    - [#53](https://github.com/nf-core/phyloplace/pull/53) - Improve adherence to Nextflow code standards [addresses #48](https://github.com/nf-core/phyloplace/issues/48) (by @erikrikarddaniel)
    - [#52](https://github.com/nf-core/phyloplace/pull/52) - Template update for nf-core/tools version 4.0.2 (by @erikrikarddaniel)

### `Dependencies`

    - [#52](https://github.com/nf-core/phyloplace/pull/52) - Update some software versions (by @erikrikarddaniel)

| software    | previously | now       |
| ----------- | ---------- | --------- |
| nextflow    | >=24.04.2  | >=25.10.4 |
| hmmer/easel | 0.48       | 0.49      |
| hmmer       | 3.3.2      | 3.4       |
| MultiQC     | 1.27       | 1.35      |

### `Deprecated`

## v2.0.0 - [2025-02-21]

This release add phylogenetic search to the pipeline.
Use `--phyloplace_input file.csv` to use the original mode, and `--phylosearch_input file.csv` to use the new phylosearch mode, see the documentation.

### `Added`

    - [#23](https://github.com/nf-core/phyloplace/pull/23) - Add search and phylogenetic classification to the pipeline (by @erikrikarddaniel)
    - [#23](https://github.com/nf-core/phyloplace/pull/23) - Add Clustal Omega as alignment tool (by @erikrikarddaniel)

### `Fixed`

    - [#32](https://github.com/nf-core/phyloplace/pull/32) - Template update for nf-core/tools version 3.2.0 (by @erikrikarddaniel)
    - [#29](https://github.com/nf-core/phyloplace/pull/29) - Template update for nf-core/tools version 3.1.1 (by @erikrikarddaniel)
    - [#21](https://github.com/nf-core/phyloplace/pull/21) - Template update for nf-core/tools version 2.12, 2.13 and 2.14 (by @erikrikarddaniel)

### `Dependencies`

### `Deprecated`

## v1.0.0 - [2023-02-15]

Initial release of nf-core/phyloplace, created with the [nf-core](https://nf-co.re/) template.

The pipeline performs phylogenetic placement of nucleotide or amino acid sequences in a reference phylogeny.
