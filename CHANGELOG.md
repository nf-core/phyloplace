# nf-core/phyloplace: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.4.1dev - [yyyy-mm-dd]

### `Added`

### `Fixed`

### `Changed`

### `Dependencies`

### `Deprecated`

## v2.4.0 - [2026-11-25]

### `Added`

- [#118](https://github.com/nf-core/phyloplace/pull/118) - `--epang_filter_max` and `--epang_filter_acc_lwr` set how many placements EPA-ng keeps per query sequence. EPA-ng keeps at most 7 by default, which leaves a low accumulated likelihood weight (`aLWR`) for query sequences with a diffuse placement ([#117](https://github.com/nf-core/phyloplace/issues/117)) (by @erikrikarddaniel, reviewed by @eduard-watchmaker)
- [#116](https://github.com/nf-core/phyloplace/pull/116) - Query sequences are filtered before placement, as EPA-NG stops the whole run on a query sequence with no residue in the columns occupied by the reference sequences. `--min_query_columns` (default 1) and `--min_reference_coverage` (default 0, off) set the thresholds, and columns with the same names set them per row in `--phyloplace_input` and `--phylosearch_input` sheets. Sequences that are dropped are reported in a warning and in `filterquery/*.filterquery.tsv`. Runs that earlier stopped with an EPA-NG error now continue without those sequences (by @erikrikarddaniel, reviewed by @eduard-watchmaker)
- [#109](https://github.com/nf-core/phyloplace/pull/109) - `--phylosearch_input` accepts a comma-separated list of target sheets, for example a shared collection of reference phylogenies together with a sheet of your own profiles. Target names must be unique across the sheets. The new `--phylosearch_targets` keeps only the listed targets (by @erikrikarddaniel, reviewed by @piplus2)

### `Fixed`

- [#119](https://github.com/nf-core/phyloplace/pull/119) - Documentation: the pipeline summary in the README and the output overview now list the filtering of query sequences, and the usage page no longer says that sample sheets must be comma separated (by @erikrikarddaniel, reviewed by @eduard-watchmaker)
- [#114](https://github.com/nf-core/phyloplace/pull/114) - Document that the reference sequences of a target sheet are always aligned, that its `hmm` column is used for the search only, and that a row without `alignmethod` uses `clustalo` ([#113](https://github.com/nf-core/phyloplace/issues/113)) (by @erikrikarddaniel, reviewed by @Joon-Klaps)

### `Changed`

- [#111](https://github.com/nf-core/phyloplace/pull/111) - Update the nf-core modules and the `fasta_hmmsearch_rank_fastas` and `fasta_newick_epang_gappa` subworkflows. The modules now use the container images of the Seqera community registry, with the same tool versions as before, and the DuckDB modules name their SQL heredoc after a hash of its content, so `-resume` no longer re-runs them (by @erikrikarddaniel, reviewed by @Joon-Klaps)
- [#110](https://github.com/nf-core/phyloplace/pull/110) - `--phyloplace_input` (sample sheet) and `--phylosearch_input` (target sheets) accept sheets in CSV, TSV, YAML and JSON format, not only CSV (by @erikrikarddaniel, reviewed by @eduard-watchmaker)
- [#108](https://github.com/nf-core/phyloplace/pull/108) - Template updated to nf-core/tools 4.2.2, which moves the Apptainer setup action of the CI workflows to v3. No pipeline code changes (by @erikrikarddaniel, reviewed by @mashehu)
- [#106](https://github.com/nf-core/phyloplace/pull/106) - Template updated to nf-core/tools 4.2.1, which changes the GitHub Actions and the tool versions used by the CI workflows and the pre-commit hooks. The Seqera Platform launch action of the full-size test is unchanged (by @erikrikarddaniel, reviewed by @mashehu and @jfy133)
- [#104](https://github.com/nf-core/phyloplace/pull/104) - Launch the AWS tests with `seqeralabs/action-seqera-launch` and the v2 syntax parser, and stop uploading the debug log as an artifact (by @erikrikarddaniel, reviewed by @piplus2)
- [#102](https://github.com/nf-core/phyloplace/pull/102) - Pin nf-schema in the launch config of the AWS full-size tests, which failed at start since nf-schema 3.0.0 (by @erikrikarddaniel)

### `Dependencies`

### `Deprecated`

## v2.3.0 - [2026-09-23]

### `Added`

- [#95](https://github.com/nf-core/phyloplace/pull/95) - Accept gzipped input files throughout the pipeline, for every samplesheet column and individual file parameter alike ([#76](https://github.com/nf-core/phyloplace/issues/76)) (by @erikrikarddaniel)

### `Changed`

- [#95](https://github.com/nf-core/phyloplace/pull/95) - Check the file name extension of every input file parameter, in samplesheets and individual parameters alike, instead of accepting any name; download URLs with no file name extension at all are still accepted (by @erikrikarddaniel)
- [#95](https://github.com/nf-core/phyloplace/pull/95) - Write the Clustal Omega and MAFFT alignments gzipped, like the rest of the pipeline's intermediate files (by @erikrikarddaniel)

### `Fixed`

- [#98](https://github.com/nf-core/phyloplace/pull/98) - Search with the profile named in `extract_hmm` also when a row's `target` equals the name of its `hmm` file, instead of silently searching with every profile in the file (by @erikrikarddaniel)
- [#97](https://github.com/nf-core/phyloplace/pull/97) - Correct the usage and output documentation (wrong parameter names in examples, wrong output file names and descriptions), document the `extract_hmm` and `min_bitscore` sample sheet columns and the search outputs, and cite Clustal Omega and DuckDB in the MultiQC methods description (by @erikrikarddaniel)
- [#96](https://github.com/nf-core/phyloplace/pull/96) - Run MAFFT with `--keeplength` as documented, so that query sequences with insertions no longer widen the reference alignment (by @erikrikarddaniel)
- [#94](https://github.com/nf-core/phyloplace/pull/94) - Memory usage in `hmmer/hmmrank`, by rewriting it from an in-memory R script to streaming DuckDB SQL ([#93](https://github.com/nf-core/phyloplace/issues/93)) (by @erikrikarddaniel)

### `Dependencies`

| software     | previously | now   |
| ------------ | ---------- | ----- |
| duckdb-cli   |            | 1.5.5 |
| gawk         |            | 5.3.1 |
| gzip         |            | 1.13  |
| nft-fasta    |            | 1.0.0 |
| nft-utils    | 0.0.3      | 1.2.0 |
| r-base       | 4.2.3      |       |
| r-data.table | 1.14.8     |       |
| r-dtplyr     | 1.3.1      |       |
| r-stringi    | 1.8.4      |       |
| r-stringr    | 1.5.1      |       |
| r-tidyverse  | 2.0.0      |       |

### `Deprecated`

## v2.2.0 - [2026-09-11]

### `Added`

- [#79](https://github.com/nf-core/phyloplace/pull/79) - New optional `reftreename` sample sheet column, grouping rows that place onto the same reference tree so that the group is also grafted, classified and heat-treed as a whole, instead of only one profile at a time ([#78](https://github.com/nf-core/phyloplace/issues/78)) (by @erikrikarddaniel)
- [#75](https://github.com/nf-core/phyloplace/pull/75) - Derive taxonomy from `--refseqfile` FASTA headers (GTDB single-file style) when `--taxonomy` is not given, instead of skipping taxonomic classification entirely ([#66](https://github.com/nf-core/phyloplace/issues/66)) (by @erikrikarddaniel)
- [#72](https://github.com/nf-core/phyloplace/pull/72) - Alignment coordinates, lengths and coverage for each hit in the ranked `hmmsearch` summary, when `--save_domtblout` is set ([#70](https://github.com/nf-core/phyloplace/issues/70)) (by @erikrikarddaniel)
- [#71](https://github.com/nf-core/phyloplace/pull/71) - New `--save_domtblout` option, saving hmmsearch's per-domain hit table in "search and place" mode ([#69](https://github.com/nf-core/phyloplace/issues/69)) (by @erikrikarddaniel)

### `Fixed`

- [#85](https://github.com/nf-core/phyloplace/pull/85) - Build every `conf/test*.config` and `tests/nextflow.config` test-data URL from `params.pipelines_testdata_base_path` (or `params.modules_testdata_base_path` for the handful that live on the shared `modules` branch instead), instead of hardcoding the full URL, so a fork's `phyloplace` branch can be tested with a single `--pipelines_testdata_base_path` override without also re-pointing the shared-branch files ([#80](https://github.com/nf-core/phyloplace/issues/80)) (by @erikrikarddaniel)
- [#84](https://github.com/nf-core/phyloplace/pull/84) - Use relative links between our own docs pages again, now that a website fix means they resolve correctly, instead of absolute links that silently pointed to the released docs ([#83](https://github.com/nf-core/phyloplace/issues/83)) (by @erikrikarddaniel)
- [#71](https://github.com/nf-core/phyloplace/pull/71) - Correct the `hmmsearch` output files listed in the output documentation, where the human-readable table was listed as `*.tbl.gz` instead of `*.txt.gz` (by @erikrikarddaniel)

### `Changed`

- [#88](https://github.com/nf-core/phyloplace/pull/88) - Change the default `--alignmethod` from `hmmer` to `clustalo`, except when `--hmmfile` is given (or filled in a samplesheet row), which still implies `hmmer`. Runs that relied on the previous default now align with Clustal Omega and produce `clustalo/` output instead of `hmmer/`; pass `--alignmethod hmmer` to keep the old behaviour (by @erikrikarddaniel)
- [#81](https://github.com/nf-core/phyloplace/pull/81) - Update `gappa/examineassign`, `gappa/examinegraft` and `gappa/examineheattree` to gappa 0.9.0, so every gappa step runs the same version and container ([nf-core/modules#12858](https://github.com/nf-core/modules/pull/12858)) (by @erikrikarddaniel)
- [#79](https://github.com/nf-core/phyloplace/pull/79) - Publish grafted trees as `<id>.graft.newick` instead of `<id>.graft.<id>.epa_result.newick`, dropping a repetition of the name and matching the new joint outputs (by @erikrikarddaniel)
- [#77](https://github.com/nf-core/phyloplace/pull/77) - Adopt typed `params` blocks for pipeline-specific parameters, fixing boolean options (e.g. `--save_domtblout false`) that couldn't be turned off from the command line ([#74](https://github.com/nf-core/phyloplace/issues/74)) (by @erikrikarddaniel). Raises the minimum required Nextflow version to `26.04.0`.
- [#73](https://github.com/nf-core/phyloplace/pull/73) - Update `seqtk/subseq` and `fasta_hmmsearch_rank_fastas` to fix output filenames glomming the input sequence filename onto the prefix ([nf-core/modules#12779](https://github.com/nf-core/modules/issues/12779)) (by @erikrikarddaniel)
- [#68](https://github.com/nf-core/phyloplace/pull/68) - Template update to 4.1.0 (by @erikrikarddaniel)

### `Dependencies`

| software  | previously | now       |
| --------- | ---------- | --------- |
| biopython |            | 1.84      |
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
