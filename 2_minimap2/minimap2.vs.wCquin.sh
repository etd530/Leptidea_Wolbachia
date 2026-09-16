#!/bin/bash

#### MAIN ####
for file1 in ../1_fastqc/*R1*.trim.fq.gz; do
    file2=`echo $file1 | sed -E 's/R1/R2/g'`;
    prefix1=`basename $file1 | sed -E 's/\.fq\.trim\.gz//g'`;
    prefix2=`basename $file2 | sed -E 's/\.fq\.trim\.gz//g'`;
    sample=`echo $prefix1 | sed -E 's/\.R[12]//g'`;
    echo $file1
    echo $file2
    echo $prefix1
    echo $prefix2
    echo $sample
    minimap2 -ax sr -t 20 -R "@RG\tID:${sample}\tSM:${sample}" ../0b_ref_genome_CI_loci/wPip.Culex_quinquefasciatus.GCF_000073005_1/wPip.Culex_quinquefasciatus.GCF_000073005_1.fna $file1 $file2 | samtools view -bhq 20 - | samtools sort -@20 -o ${sample}.vs.wCquin.bam && samtools index ${sample}.vs.wCquin.bam;
done
