#!/usr/bin/env bash

#### MODULES ####
module load bakta/1.12.0-foss-2024a
set -euo pipefail

#### VARS ####
assembly=$1
threads=$2

prefix=$(basename $assembly | cut -f1,2,3,4 -d'.')

#### MAIN ####
bakta --db $BAKTA_DB --force --min-contig-length 1000 --prefix $prefix --output bakta/$prefix.bakta --genus Wolbachia --species "sp." --strain 'Wolbachia endosymbiont of Leptidea' --keep-contig-headers --threads $threads $assembly
