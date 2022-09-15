nextflow.enable.dsl = 2

include { HMMER_HMMBUILD                              } from '../../modules/nf-core/modules/hmmer/hmmbuild/main'
include { HMMER_HMMALIGN as HMMALIGNREF               } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_HMMALIGN as HMMALIGNQUERY             } from '../../modules/nf-core/modules/hmmer/hmmalign/main'
include { HMMER_ESLALIMASK                            } from '../../modules/nf-core/modules/hmmer/eslalimask/main'
include { HMMER_ESLREFORMAT as UNALIGN_INPUT_REF      } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as AFAFORMAT_OUTPUT_REF   } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { HMMER_ESLREFORMAT as AFAFORMAT_OUTPUT_QUERY } from '../../modules/nf-core/modules/hmmer/eslreformat/main'
include { EPANG                                       } from '../../modules/nf-core/modules/epang/main'

workflow EPA_NG_PLACEMENT {

    take:
    ch_pp_data

    main:
    ch_versions = Channel.empty()
    //ch_pp_data.view { "pp_data: $it" }

    HMMER_HMMBUILD ( ch_pp_data.map { [ it.meta, it.data.refalignment ] }, [] )
    ch_versions = ch_versions.mix(HMMER_HMMBUILD.out.versions.first())

    // We need to "unalign"
    UNALIGN_INPUT_REF ( ch_pp_data.map { [ it.meta, it.data.refalignment ] } )
    ch_versions = ch_versions.mix(UNALIGN_INPUT_REF.out.versions)

    //HMMALIGNREF ( ch_pp_data.map { [ it.meta, it.data.refalignment ] }, HMMER_HMMBUILD.out.hmm.map { it[1] } )
    //ch_versions = ch_versions.mix(HMMALIGNREF.out.versions)

    emit:
    versions = ch_versions
}
