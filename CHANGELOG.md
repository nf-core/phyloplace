# nf-core/phyloplace: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
