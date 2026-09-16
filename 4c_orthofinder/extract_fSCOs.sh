#!/usr/bin/env bash

# Get seqs of all the fSCOs at 95% presence according to Kinfin
mkdir -p 95_fSCOs

for og in `cut -f1 kinfin/kinfin_95_.kinfin_results/all/all.all.cluster_1to1s.txt | egrep -v '#'`;
do echo $og;
ln -sf ../proteomes/OrthoFinder/Results_leptidea_wolbachia/Orthogroup_Sequences/${og}.fa 95_fSCOs/${og}.fa;
done
