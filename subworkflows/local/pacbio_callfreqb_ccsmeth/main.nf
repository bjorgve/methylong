/*
===========================================
 * Import processes from modules
===========================================
 */

include { CCSMETH_CALLFREQB                } from '../../../modules/local/ccsmeth/callfreqb/main'
include { SAMTOOLS_FAIDX                     } from '../../../modules/nf-core/samtools/faidx/main'
include { TABIX_TABIX                   } from '../../../modules/nf-core/tabix/tabix/main'

/*
===========================================
 * Workflows
===========================================
 */


// for PacBio

workflow PACBIO_CALLFREQB_CCSMETH {
    take:
    input

    main:

    // Prepare inputs

    input
        .multiMap { meta, bam, _bai, ref ->
            bam_in: [meta, bam]
            ref_in: [meta, ref]
        }
        .set { ch_pileup_in }

    // ccsmeth call_freqb
    CCSMETH_CALLFREQB(ch_pileup_in.bam_in, ch_pileup_in.ref_in)

    CCSMETH_CALLFREQB.out.bed.set { pileup_out }
    TABIX_TABIX(CCSMETH_CALLFREQB.out.bed)

    emit:
    pileup_out
}
