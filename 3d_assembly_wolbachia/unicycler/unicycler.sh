#!/bin/bash -l

#### MODULES ####
conda activate unicycler
set -euo pipefail

#### VARS ####
reads1=$1
reads2=${reads1/.R1./.R2.}
prefix=$(basename $reads1 | cut -f1,2,3,4 -d'.')

#### MAIN ####
unicycler -1 $reads1 -2 $reads2 -o ${prefix}.unicycler && touch $prefix.unicycler.DONE || touch $prefix.unicycler.FAILED
