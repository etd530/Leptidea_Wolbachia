#!/usr/bin/env bash

#### MODULES ####
module load BUSCO/5.8.2-gfbf-2024a
set -euo pipefail

#### VARS ####
assembly=$1
threads=$2

#### MAIN ####
prefix=$(dirname $assembly)
busco -m genome -i $assembly -o $prefix.busco_rickettsiales_odb12 -l rickettsiales_odb12 -c $threads

# -l $BUSCO_LINEAGE_SETS/fungi_odb12
