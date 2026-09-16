#!/usr/bin/env bash

#### MODULES ####
module load SAMtools/1.22.1-GCC-13.3.0

#### VARS ####
asm=$1
prefix=$(basename $asm .spades.scaffolds.fasta)
table=blobtools/${prefix}.blobDB.table.txt

grep -v '^#' $table | grep -P '\tRickettsiales\t' | cut -f1 | less > $prefix.rickettsiales_ctgs.txt
if [ -s $prefix.rickettsiales_ctgs.txt ]; then
	echo "Rickettsiales contigs found in $asm" && \
	samtools faidx -r $prefix.rickettsiales_ctgs.txt $asm > ../spades_filtered/assemblies/${prefix}.spades_filtered.scaffolds.fasta
else
	echo "No Rickettsiales contigs found in $asm"
fi
