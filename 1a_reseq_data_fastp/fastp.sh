#!/bin/bash

#### MAIN ####
mkdir -p fastp_reports
for file1 in ../0a_reseq_data/*{rea,sin}*R1*; do
    file2=`echo $file1 | sed -E 's/R1/R2/g'`;
    prefix1=`basename $file1 | sed -E 's/\.fastq\.gz//g'`;
    prefix2=`basename $file2 | sed -E 's/\.fastq\.gz//g'`;
    fastp -i ${file1} -I ${file2} -o ${prefix1}.trim.fq.gz -O ${prefix2}.trim.fq.gz --detect_adapter_for_pe --cut_front --cut_tail --cut_by_quality3 --cut_window_size 4 --cut_mean_quality 20 --correction --html fastp_reports/${prefix1}.html --json fastp_reports/${prefix1}.json --thread 16;
done;
