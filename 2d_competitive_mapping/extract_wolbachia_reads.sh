#!/usr/bin/env bash

#### VARS ####
bamfile_list=(*.vs.drep_ani99_maf90.bam)
bamfile=${bamfile_list[$SLURM_ARRAY_TASK_ID]}
threads=10
sample=$(basename $bamfile .trim.fq.gz.vs.drep_ani99_maf90.bam)

#### MAIN ####
# Extract all reads except those for which the mate is unmapped (since we want equal number of R1 and R2 reads for the assembler downstream
# Since unmapped reads were discarded already by filtering the BAM file, this gives us reads that are mapped and whose mate is also mapped
# Before extracting, we sort by read names so that mate pairs are in the same lines in the FASTQ output
samtools sort -@${threads} -n $bamfile | samtools fastq -F 8 -@${threads} -1 ${sample}.wolbachia_reads.R1.fq.gz -2 ${sample}.wolbachia_reads.R2.fq.gz -n - && touch ${sample}.samtools_fastq.DONE || touch ${sample}.samtools_fastq.FAILED
