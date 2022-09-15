nextflow.enable.dsl = 2

include { HMMER_HMMBUILD as EPANGPP_HMMBUILD                  } from '../../modules/nf-core/modules/hmmer/hmmbuild/main'
include { HMMER_HMMALIGN as EPANGPP_HMMALIGNREF               } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_HMMALIGN as EPANGPP_HMMALIGNQUERY             } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_ESLALIMASK as EPANGPP_MASKREF                 } from '../../modules/nf-core/modules/hmmer/eslalimask/main'
include { HMMER_ESLALIMASK as EPANGPP_MASKQUERY               } from '../../modules/nf-core/modules/hmmer/eslalimask/main'
include { HMMER_ESLREFORMAT as EPANGPP_UNALIGN_INPUT_REF      } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as EPANGPP_AFAFORMAT_OUTPUT_REF   } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as EPANGPP_AFAFORMAT_OUTPUT_QUERY } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { EPANG as EPANGPP_EPANG                              } from '../../modules/nf-core/modules/epang/main'

workflow EPA_NG_PLACEMENT {

    take:
    ch_pp_data

    main:
    ch_versions = Channel.empty()
    //ch_pp_data.view { "pp_data: $it" }

    EPANGPP_HMMBUILD ( ch_pp_data.map { [ it.meta, it.data.refalignment ] }, [] )
    ch_versions = ch_versions.mix(EPANGPP_HMMBUILD.out.versions.first())

    // We need to "unalign" the reference sequences before they can be aligned to the hmm.
    EPANGPP_UNALIGN_INPUT_REF ( ch_pp_data.map { [ it.meta, it.data.refalignment ] } )
    ch_versions = ch_versions.mix(EPANGPP_UNALIGN_INPUT_REF.out.versions)

    EPANGPP_HMMALIGNREF ( EPANGPP_UNALIGN_INPUT_REF.out.seqreformated, EPANGPP_HMMBUILD.out.hmm.map { it[1] } )
    ch_versions = ch_versions.mix(EPANGPP_HMMALIGNREF.out.versions)

    emit:
    versions = ch_versions
}
