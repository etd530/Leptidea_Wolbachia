#!/usr/bin/env bash

#### MODULES ####

#### VARS ####
samples_list=samples_list.txt

while read sample; do
	batch_num=$(ls ${sample}*.R1.fq.gz | wc -l)
	if [ $batch_num -eq "1" ]; then
		mv -v ${sample}.batch_1.wolbachia_reads.R1.fq.gz ${sample}.merged.wolbachia_reads.R1.fq.gz
		mv -v ${sample}.batch_1.wolbachia_reads.R2.fq.gz ${sample}.merged.wolbachia_reads.R2.fq.gz
	else
		cat ${sample}.batch_*.wolbachia_reads.R1.fq.gz > ${sample}.merged.wolbachia_reads.R1.fq.gz && rm -fv ${sample}.batch_*.wolbachia_reads.R1.fq.gz
		cat ${sample}.batch_*.wolbachia_reads.R2.fq.gz > ${sample}.merged.wolbachia_reads.R2.fq.gz && rm -fv ${sample}.batch_*.wolbachia_reads.R2.fq.gz
	fi
done < $samples_list
