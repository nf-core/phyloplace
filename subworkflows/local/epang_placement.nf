nextflow.enable.dsl = 2

include { HMMER_HMMBUILD as HMMER_HMMBUILD          } from '../../modules/nf-core/modules/hmmer/hmmbuild/main'
include { HMMER_HMMALIGN as HMMER_HMMALIGNREF       } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_HMMALIGN as HMMER_HMMALIGNQUERY     } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_ESLALIMASK as HMMER_MASKREF         } from '../../modules/nf-core/modules/hmmer/eslalimask/main'
include { HMMER_ESLALIMASK as HMMER_MASKQUERY       } from '../../modules/nf-core/modules/hmmer/eslalimask/main'
include { HMMER_ESLREFORMAT as HMMER_UNALIGNREF     } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as HMMER_AFAFORMATREF   } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as HMMER_AFAFORMATQUERY } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { EPANG                                     } from '../../modules/nf-core/modules/epang/main'
include { GAPPA_EXAMINEGRAFT as GAPPA_GRAFT         } from '../../modules/nf-core/modules/gappa/examinegraft/main'
include { GAPPA_EXAMINEASSIGN as GAPPA_ASSIGN       } from '../../modules/nf-core/modules/gappa/examineassign/main'

workflow EPANG_PLACEMENT {

    take:
    ch_pp_data

    main:
    ch_versions = Channel.empty()

    // 1. Build an hmm profile to use for alignment
    HMMER_HMMBUILD ( ch_pp_data.map { [ it.meta, it.data.refalignment ] }, [] )
    ch_versions = ch_versions.mix(HMMER_HMMBUILD.out.versions.first())

    // 2. We need to "unalign" the reference sequences before they can be aligned to the hmm.
    // (Add ext.args = "--gapsym=- afa" and ext.postprocessing = '| sed "/^>/!s/-//g"' in config file for the process.)
    HMMER_UNALIGNREF ( ch_pp_data.map { [ it.meta, it.data.refalignment ] } )
    ch_versions = ch_versions.mix(HMMER_UNALIGNREF.out.versions)

    // 3. Align the reference and query sequences to the profile
    HMMER_HMMALIGNREF ( HMMER_UNALIGNREF.out.seqreformated, HMMER_HMMBUILD.out.hmm.map { it[1] } )
    ch_versions = ch_versions.mix(HMMER_HMMALIGNREF.out.versions)

    HMMER_HMMALIGNQUERY ( ch_pp_data.map { [ it.meta, it.data.queryfile ] }, HMMER_HMMBUILD.out.hmm.map { it[1] } )
    ch_versions = ch_versions.mix(HMMER_HMMALIGNQUERY.out.versions)

    // 4. Mask the alignments (Add '--rf-is-mask' ext.args in config for the process.)
    HMMER_MASKREF ( HMMER_HMMALIGNREF.out.sthlm.map { [ it[0], it[1], [], [], [], [], [], [] ] }, [] )
    ch_versions = ch_versions.mix(HMMER_MASKREF.out.versions)

    HMMER_MASKQUERY ( HMMER_HMMALIGNQUERY.out.sthlm.map { [ it[0], it[1], [], [], [], [], [], [] ] }, [] )
    ch_versions = ch_versions.mix(HMMER_MASKQUERY.out.versions)

    // 5. Reformat alignments to "afa" (aligned fasta)
    HMMER_AFAFORMATREF ( HMMER_MASKREF.out.maskedaln )
    ch_versions = ch_versions.mix(HMMER_AFAFORMATREF.out.versions)

    HMMER_AFAFORMATQUERY ( HMMER_MASKQUERY.out.maskedaln )
    ch_versions = ch_versions.mix(HMMER_AFAFORMATQUERY.out.versions)

    // 6. Do the actual placement
    ch_epang_query = ch_pp_data.map { [ it.meta, it.data.model ] }
        .join ( HMMER_AFAFORMATQUERY.out.seqreformated )
        .map { [ [ id:it[0].id, model:it[1] ], it[2] ] }
    EPANG (
        ch_epang_query,
        HMMER_AFAFORMATREF.out.seqreformated.map { it[1] },
        ch_pp_data.map { it.data.refphylogeny },
        [], [], []
    )
    ch_versions = ch_versions.mix(EPANG.out.versions)

    // 7. Calculate a tree with the placed sequences
    GAPPA_GRAFT ( EPANG.out.jplace )
    ch_versions = ch_versions.mix(GAPPA_GRAFT.out.versions)

    // 8. Classify
    GAPPA_ASSIGN ( EPANG.out.jplace, ch_pp_data.map { it.data.taxonomy } )
    ch_versions = ch_versions.mix(GAPPA_ASSIGN.out.versions)

    emit:
    epang    = EPANG.out.epang
    jplace   = EPANG.out.jplace
    versions = ch_versions
}
