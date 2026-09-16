#!/bin/bash -l

#### VARS ####
aln=supermatrix/Concatenated_Alignment.fasta
parts=supermatrix/Data_Partitions.txt
threads=$SLURM_CPUS_PER_TASK

#### MAIN ####
mkdir -p iqtree && \
iqtree -s $aln --seqtype DNA -p $parts -m MFP -B 1000 --bnni --alrt 1000 -T $threads --safe --prefix iqtree/leptidea_wolbachia_phylo_small --redo && \
touch leptidea_wolbachia_phylo_small.DONE || touch leptidea_wolbachia_phylo_small.FAILED
