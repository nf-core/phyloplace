# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Note: this is an nf-core pipeline repo. Per nf-core core-team consensus, these repos use
> `AGENTS.md` instead of a committed `CLAUDE.md` at the root.

## What this pipeline does

nf-core/phyloplace performs phylogenetic placement of query sequences onto a reference
phylogeny using EPA-NG, optionally preceded by an HMMER-based sequence search step. Pipeline
summary: (1) optionally search a fasta file with HMMER profiles to select query sequences,
(2) align query sequences to a reference alignment with HMMER, Clustal Omega, or MAFFT,
(3) place them in the reference phylogeny with EPA-NG, (4) graft placements onto the
reference phylogeny with GAPPA, (5) optionally classify query sequences taxonomically with
GAPPA if a reference taxonomy is supplied.

## Common commands

Lint and test commands (run before considering any change ready, or before a PR — the nf-core
CI runs equivalents of all of these):

```bash
prek run -a                       # pre-commit hooks: prettier, trailing-whitespace, end-of-file-fixer, nextflow-lint
nf-core pipelines lint            # nf-core community pipeline-standards lint (add --release for PRs targeting master)
nextflow lint .                   # Nextflow strict-syntax lint; run against both the declared minimum
                                   # Nextflow version (nextflowVersion in nextflow.config, currently
                                   # '!>=25.10.4') and latest, via NXF_VER=<version> nextflow lint .
```

`prek` and `nf-core` are available in the `nf-core` conda env if not already on `PATH`
(`conda activate nf-core`).

Running the pipeline against its test profiles (mirrors `.github/workflows/ci.yml`):

```bash
nextflow run . -profile test,docker --outdir ./results               # basic phyloplace, single sample via individual params
nextflow run . -profile test_phyloplace_input,docker --outdir ./results   # phyloplace via samplesheet
nextflow run . -profile test_phylosearch_input,docker --outdir ./results  # search-then-place via samplesheet
nextflow run . -profile test_hmmfile,docker --outdir ./results        # phyloplace with a pre-built hmm file
nextflow run . -profile test_clustalo,docker --outdir ./results       # alignmethod: clustalo
nextflow run . -profile test_mafft,docker --outdir ./results          # alignmethod: mafft
```

Running the nf-test suite (snapshot-based; see `tests/*.nf.test` / `*.nf.test.snap`):

```bash
nf-test test                                  # whole suite
nf-test test tests/default.nf.test             # a single test file
nf-test test --update-snapshot tests/default.nf.test  # regenerate a snapshot after an intentional output change
```

Each `tests/*.nf.test` file runs `main.nf` end-to-end under one `conf/test_*.config` profile
and asserts against a `.nf.test.snap` snapshot (stable file paths/contents under `outdir`,
plus row counts for the GAPPA taxonomy TSVs). Before the first real run after any module
version bump, check whether the affected tool's version string is embedded in the relevant
`.nf.test.snap` (`grep -rn '"<tool>":' tests/*.snap`) — if so, pre-patch it to avoid a wasted
fail/update-snapshot cycle for a change that isn't behavioral.

## Architecture

This follows the standard nf-core DSL2 template shape (`main.nf` → `workflows/phyloplace.nf`
→ `subworkflows/` → `modules/`), but the pipeline-specific logic worth understanding lives in
two nested subworkflows plus the channel-shaping logic that feeds them.

**Two input modes, unified into one data shape.** `PIPELINE_INITIALISATION` (in
`subworkflows/local/utils_nfcore_phyloplace_pipeline/main.nf`) builds one of two channels
depending on which parameters are set:

- `ch_phyloplace_data`: direct placement jobs, each a
  `[meta: [id], data: [alignmethod, queryseqfile, refseqfile, refphylogeny, hmmfile, model, taxonomy]]`
  map. Populated from `--phyloplace_input` samplesheet, or from the individual
  `--queryseqfile/--refseqfile/--refphylogeny/--model/...` params for a single ad hoc run.
- `ch_phylosearch_data`: search-then-place jobs, each a
  `[meta: [id], data: [alignmethod, hmm, extract_hmm, refseqfile, refphylogeny, model, taxonomy]]`
  map, populated from `--phylosearch_input` + `--search_fasta`. Entries lacking
  `refphylogeny`/`refseqfile`/`alignmethod` are search-only (see `rnr` example in
  `docs/usage.md`) — they get filtered out before feeding phylogenetic placement and only
  contribute a search-result fasta.

These are two different samplesheet schemas: `assets/schema_phyloplace_input.json` and
`assets/schema_phylosearch_input.json`, validated via `plugin/nf-schema`'s
`samplesheetToList`. Exactly one of the three input styles (`phyloplace_input`,
`phylosearch_input` + `search_fasta`, or the individual params) must be provided — enforced
by if/else branching in `PIPELINE_INITIALISATION`, not by the JSON schemas themselves.

**`workflows/phyloplace.nf`** stitches the search branch into the placement branch: it runs
`HMMER_HMMEXTRACT` (local module) for entries needing a named profile extracted from a
larger hmm, then `FASTA_HMMSEARCH_RANK_FASTAS` to search/rank hits, then joins the resulting
per-target fastas back onto the placement metadata from `ch_phylosearch_data` to build
additional entries for `ch_phyloplace_data`, which is finally passed into
`FASTA_NEWICK_EPANG_GAPPA`.

**`subworkflows/nf-core/fasta_hmmsearch_rank_fastas`**: runs `HMMER_HMMSEARCH` per
profile/fasta pair, ranks hits across all profiles with `HMMER_HMMRANK` (this pipeline's own
module — resolves cases where a sequence would match multiple profiles), keeps only rank-1
hits per profile, and extracts those sequences per-profile with `SEQTK_SUBSEQ`.

**`subworkflows/nf-core/fasta_newick_epang_gappa`** is the core placement subworkflow and the
most complex part of the pipeline. It branches the incoming channel three ways by
`data.alignmethod` (`hmmer` / `clustalo` / `mafft`), since each alignment method has a
different multi-step process to get query and reference sequences into a split,
EPA-NG-compatible alignment pair:

- `hmmer`: build an hmm from the reference alignment if none was given (`HMMER_HMMBUILD`),
  unalign the reference if needed, align both reference and query to the (possibly newly
  built) hmm profile (`HMMER_HMMALIGN`, called twice via `as HMMER_HMMALIGNREF`/
  `HMMER_HMMALIGNQUERY`), mask (`HMMER_ESLALIMASK`), then reformat to aligned fasta
  (`HMMER_ESLREFORMAT`). Several of these steps use `groupTuple(size: 2, sort: ...)` to pair
  an hmm profile with its sequence file by regex-matching the `.hmm` extension — order
  matters when modifying this.
- `clustalo` / `mafft`: profile-align query sequences against the reference alignment
  directly (`CLUSTALO_ALIGN` / `MAFFT_ALIGN`), then split the combined alignment back into
  reference/query parts with `EPANG_SPLIT` (instantiated twice, once per method, as
  `EPANG_SPLIT_CLUSTALO`/`EPANG_SPLIT_MAFFT`).

All three branches converge into one `ch_epang_query` channel keyed by
`[id, model]` and feed `EPANG_PLACE`, whose `jplace` output then feeds `GAPPA_EXAMINEGRAFT`
(full grafted tree), `GAPPA_EXAMINEASSIGN` (taxonomic classification, only when a `taxonomy`
file was supplied — joined back in from the original data channel), and
`GAPPA_EXAMINEHEATTREE` (SVG heat tree).

**Local vs nf-core modules/subworkflows**: `modules/local/hmmer/hmmextract` and both
subworkflows under `subworkflows/nf-core/` (`fasta_hmmsearch_rank_fastas`,
`fasta_newick_epang_gappa`) are pipeline-specific despite one pair living under the
`nf-core/` subworkflow directory name — everything else under `modules/nf-core/` and
`subworkflows/nf-core/utils_*` is vendored, unmodified nf-core community code and should be
updated via `nf-core modules update` / `nf-core subworkflows update`, not edited by hand.

## Template syncs and module updates

See the global nf-core guidance already loaded into this session for the mechanics of
`nf-core pipelines sync`, `nf-core modules update --all --no-preview`, and
`nf-core subworkflows update --all --no-preview` (branch strategy, patch reapplication,
`nf-core pipelines lint --fix`, changelog conventions). It is not repeated here.
