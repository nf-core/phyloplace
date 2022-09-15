nextflow.enable.dsl = 2

include { HMMER_HMMBUILD as EPANGPP_HMMBUILD          } from '../../modules/nf-core/modules/hmmer/hmmbuild/main'
include { HMMER_HMMALIGN as EPANGPP_HMMALIGNREF       } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_HMMALIGN as EPANGPP_HMMALIGNQUERY     } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_ESLALIMASK as EPANGPP_MASKREF         } from '../../modules/nf-core/modules/hmmer/eslalimask/main'
include { HMMER_ESLALIMASK as EPANGPP_MASKQUERY       } from '../../modules/nf-core/modules/hmmer/eslalimask/main'
include { HMMER_ESLREFORMAT as EPANGPP_UNALIGNREF     } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as EPANGPP_AFAFORMATREF   } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as EPANGPP_AFAFORMATQUERY } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { EPANG as EPANGPP_EPANG                      } from '../../modules/nf-core/modules/epang/main'
include { GAPPA_EXAMINEGRAFT as EPANGPP_GRAFT         } from '../../modules/nf-core/modules/gappa/examinegraft/main'

workflow EPA_NG_PLACEMENT {

    take:
    ch_pp_data

    main:
    ch_versions = Channel.empty()

    // 1. Build an hmm profile to use for alignment
    EPANGPP_HMMBUILD ( ch_pp_data.map { [ it.meta, it.data.refalignment ] }, [] )
    ch_versions = ch_versions.mix(EPANGPP_HMMBUILD.out.versions.first())

    // 2. We need to "unalign" the reference sequences before they can be aligned to the hmm.
    // (Add ext.args = "--gapsym=- afa" and ext.postprocessing = '| sed "/^>/!s/-//g"' in config file for the process.)
    EPANGPP_UNALIGNREF ( ch_pp_data.map { [ it.meta, it.data.refalignment ] } )
    ch_versions = ch_versions.mix(EPANGPP_UNALIGNREF.out.versions)

    // 3. Align the reference and query sequences to the profile
    EPANGPP_HMMALIGNREF ( EPANGPP_UNALIGNREF.out.seqreformated, EPANGPP_HMMBUILD.out.hmm.map { it[1] } )
    ch_versions = ch_versions.mix(EPANGPP_HMMALIGNREF.out.versions)

    EPANGPP_HMMALIGNQUERY ( ch_pp_data.map { [ it.meta, it.data.queryfile ] }, EPANGPP_HMMBUILD.out.hmm.map { it[1] } )
    ch_versions = ch_versions.mix(EPANGPP_HMMALIGNQUERY.out.versions)

    // 4. Mask the alignments (Add '--rf-is-mask' ext.args in config for the process.)
    EPANGPP_MASKREF ( EPANGPP_HMMALIGNREF.out.sthlm.map { [ it[0], it[1], [], [], [], [], [], [] ] }, [] )
    ch_versions = ch_versions.mix(EPANGPP_MASKREF.out.versions)

    EPANGPP_MASKQUERY ( EPANGPP_HMMALIGNQUERY.out.sthlm.map { [ it[0], it[1], [], [], [], [], [], [] ] }, [] )
    ch_versions = ch_versions.mix(EPANGPP_MASKQUERY.out.versions)

    // 5. Reformat alignments to "afa" (aligned fasta)
    EPANGPP_AFAFORMATREF ( EPANGPP_MASKREF.out.maskedaln )
    ch_versions = ch_versions.mix(EPANGPP_AFAFORMATREF.out.versions)

    EPANGPP_AFAFORMATQUERY ( EPANGPP_MASKQUERY.out.maskedaln )
    ch_versions = ch_versions.mix(EPANGPP_AFAFORMATQUERY.out.versions)

    // 6. Do the actual placement
    ch_epang_query = ch_pp_data.map { [ it.meta, it.data.model ] }
        .join ( EPANGPP_AFAFORMATQUERY.out.seqreformated )
        .map { [ [ id:it[0].id, model:it[1] ], it[2] ] }
    EPANGPP_EPANG (
        ch_epang_query,
        EPANGPP_AFAFORMATREF.out.seqreformated.map { it[1] },
        ch_pp_data.map { it.data.refphylogeny },
        [], [], []
    )
    ch_versions = ch_versions.mix(EPANGPP_EPANG.out.versions)

    // 7. Calculate a tree with the placed sequences
    EPANGPP_GRAFT ( EPANGPP_EPANG.out.jplace )
    ch_versions = ch_versions.mix(EPANGPP_GRAFT.out.versions)

    emit:
    epang    = EPANGPP_EPANG.out.epang
    jplace   = EPANGPP_EPANG.out.jplace
    versions = ch_versions
}
