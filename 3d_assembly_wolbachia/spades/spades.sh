#!/usr/bin/env bash

set -euo pipefail

#### VARS ####
reads1=$1
threads=$2

reads2=$(echo $reads1 | sed -E s'/R1/R2/g')

prefix=$(basename $reads1 .R1.fq.gz)

#### MAIN ####
echo "Processing sample ${prefix}..."

#### MODULES ####
module load SPAdes/4.2.0-GCC-13.3.0

# Interleave the read files
# reformat.sh in1=$reads1 in2=$reads2 out=${prefix}.interleaved.fq.gz && echo "FASTQ files interleaved." && \

# Run SPAdes
spades.py -o ${prefix}.spades -1 $reads1 -2 $reads2 -t $threads && touch ${prefix}.DONE || touch ${prefix}.FAILED
