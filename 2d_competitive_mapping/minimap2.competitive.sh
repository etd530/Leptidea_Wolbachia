#!/usr/bin/env bash

#### VARS ####
file1_list=(../1a_reseq_fastqc/*R1*trim.fq.gz)
file1=${file1_list[$SLURM_ARRAY_TASK_ID]}

#### MAIN ####
file2=`echo $file1 | sed -E 's/R1/R2/g'`;
prefix1=`basename $file1 | sed -E 's/\.fq\.trim\.gz//g'`;
prefix2=`basename $file2 | sed -E 's/\.fq\.trim\.gz//g'`;
sample=`echo $prefix1 | sed -E 's/\.R[12]//g'`;
echo $prefix1
minimap2 -ax sr -t 20 -R "@RG\tID:${sample}\tSM:${sample}" ../0b_ref_genome_CI_loci/wolbachia.genomes.dereplicated_ani99_maf90_concat.fna $file1 $file2 | samtools view -bhF 4 - | samtools sort -@20 -o ${sample}.vs.drep_ani99_maf90.bam && samtools index ${sample}.vs.drep_ani99_maf90.bam;
