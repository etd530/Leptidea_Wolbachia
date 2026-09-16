#!/bin/bash -l

#### MODULES ####
module load meryl/1.4.1-GCCcore-13.3.0
module load merqury/20240628-1ad7c32-gfbf-2024a
set -euo pipefail

#### VARS ####
reads1=$1
reads2=$2
asm=$3
threads=$4
k=21                    # we use k=15 which is the suggested by best_k.sh with the genome size of ~ 1,293,633 (average of the preliminary assemblies we got)

sample=$(basename $asm | cut -f1,2,3,4 -d'.')
echo "Sample $sample"

#### MAIN ####
# Generate output folder
mkdir -p meryl
mkdir -p merqury

# Generate meryl kmer counts
echo "Generating meryl database..."
meryl count k=$k $reads1 threads=$threads output meryl/$sample.R1.meryl
meryl count k=$k $reads2 threads=$threads output meryl/$sample.R2.meryl
meryl union-sum output meryl/$sample.merged.meryl meryl/$sample.R?.meryl*
rm -rfv meryl/$sample.R1.meryl meryl/$sample.R2.meryl

# Run Merqury
echo "Meryl databased generated! Running merqury..."
merqury.sh meryl/$sample.merged.meryl $asm $sample.merqury && mv -v $sample.merqury* merqury/
echo "Script finished!"
