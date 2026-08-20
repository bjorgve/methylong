process DORADO_ALIGNER {
    tag "${meta.id}"
    label 'process_high'

    container "docker.io/nanoporetech/dorado:sha38b4ce849afa13eac8075f0b41cecd30799f169b"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(ref)

    output:
    // `**.bam` matches both the nested per-run layout of dorado >= 1.4
    // (<sample>/<experiment>/<run>/bam_pass/.../*.bam) and the single merged
    // <sample>/<sample>.bam written below; `**/*.bam` would miss the latter.
    tuple val(meta), path("${meta.id}/**.bam"), emit: bam
    tuple val(meta), path("${meta.id}/**.bai"), emit: bai
    tuple val("${task.process}"), val('dorado'), eval("dorado --version 2>&1 | head -n1"),
    topic: versions,
    emit: versions_dorado

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    dorado aligner \\
        -t ${task.cpus} \\
        ${ref} \\
        ${reads} \\
        ${args}

    # dorado >= 1.4 writes one BAM per sequencing run into a nested folder
    # tree under --output-dir (<sample>/<experiment>/<run>/bam_pass/...).
    # A sample whose input BAM was merged from several runs (flowcells)
    # therefore comes back as several BAMs, and every downstream module
    # expects exactly one BAM per sample. Merge them back into one
    # coordinate-sorted, indexed BAM. Single-run inputs are left untouched.
    mapfile -t bams < <(find ${meta.id} -name '*.bam' | sort)
    if [ "\${#bams[@]}" -gt 1 ]; then
        samtools merge -@ ${task.cpus} -o ${meta.id}/${meta.id}.bam "\${bams[@]}"
        samtools index -@ ${task.cpus} ${meta.id}/${meta.id}.bam
        for b in "\${bams[@]}"; do rm -f "\$b" "\$b.bai"; done
    fi

    """

    stub:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${meta.id}
    touch ${meta.id}/${meta.id}.bam
    touch ${meta.id}/${meta.id}.bam.bai

    """
}
