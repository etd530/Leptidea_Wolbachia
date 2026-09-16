#!/usr/bin/env bash

#### MODULES ####
module load bakta/1.12.0-foss-2024a
set -euo pipefail

#### VARS ####
assembly=$1
threads=$2

prefix=$(dirname $assembly)

#### MAIN ####
bakta --db $BAKTA_DB --min-contig-length 1000 --prefix $prefix --output $prefix.bakta --genus Wolbachia --species "sp." --strain 'Wolbachia endosymbiont of Leptidea' --keep-contig-headers --threads $threads $assembly
