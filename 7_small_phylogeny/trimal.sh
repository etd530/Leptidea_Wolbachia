#!/usr/bin/env bash

#### VARS ####
fasta=$1
fasta_pre=$(basename $fasta .aln.fa)

#### MAIN ####
mkdir -p trimmed_alns && \
trimal -in ${fasta} -out trimmed_alns/${fasta_pre}.trimal.fa -htmlout trimmed_alns/${fasta_pre}.html -automated1
