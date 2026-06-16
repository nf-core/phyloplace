# nf-core/phyloplace: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.1.0dev - [yyyy-mm-dd]

### `Added`

### `Fixed`

### `Dependencies`

| software    | previously | now       |
| ----------- | ---------- | --------- |

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
