#!/usr/bin/env bash

#### VARS ####
fasta=$1
threads=$2

fasta_pre=$(basename $fasta .fa)
fast_pre=$(basename $fasta .fasta)

#### MAIN ####
mkdir -p alignments && \
if [ ! -s alignments/${fasta_pre}.aln.fa ]; then
        mafft --thread $threads --genafpair --maxiterate 1000 ${fasta} > alignments/${fasta_pre}.aln.fa
fi
