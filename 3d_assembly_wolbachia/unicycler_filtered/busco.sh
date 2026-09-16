#!/usr/bin/env bash

#### MODULES ####
module load BUSCO/5.8.2-gfbf-2024a
set -euo pipefail

#### VARS ####
assembly=$1
threads=$2

#### MAIN ####
prefix=$(basename $assembly .unicycler_filtered.asm.fasta)
busco -m genome -i $assembly -o busco/$prefix.busco_rickettsiales_odb12 -l /sw/data/local/BUSCO_Data/v6/lineages/rickettsiales_odb12 -c $threads
