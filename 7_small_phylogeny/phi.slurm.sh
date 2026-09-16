#!/bin/bash -l

#### MAIN ####
for aln in ../alignments/*aln.fa; do
        aln_pre=$(basename $aln .aln.fa) && \
        Phi -f $aln -t D -o && \
        mv Phi.inf.list phi.$aln_pre.inf.list && \
        mv Phi.inf.sites phi.$aln_pre.inf.sites && \
        mv Phi.log phi.$aln_pre.log && \
        mv Phi.poly.unambig.sites phi.$aln_pre.poly.unambig.sites && \
        touch phi.$aln_pre.$SLURM_JOB_ID.DONE || touch phi.$aln_pre.$SLURM_JOB_ID.FAILED
done && \

# Summarise results
echo -e "Orthogroup\tInformative_sites\tPHI_p-value" > phipack_summary.tsv && \
for file in *DONE; do
        echo $file && \
        aln_pre=$(echo $file | cut -f2 -d'.') && \
        inf_sites=$(grep 'Found' phi.$aln_pre.log | cut -f2 -d' ') && \
        phi_pvalue=$(grep 'PHI' phi.$aln_pre.log | tr -s ' ' | cut -f3 -d' ') && \
        echo -e "$aln_pre\t$inf_sites\t$phi_pvalue" >> phipack_summary.tsv
done
