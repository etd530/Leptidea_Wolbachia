#!/usr/bin/env bash

#### VARS ####
threads=$SLURM_CPUS_PER_TASK

#### MAIN ####
mkdir -p /scratch/etode/leptidea_wolbachia_orthofinder/ && \
orthofinder -f proteomes -n leptidea_wolbachia -p /scratch/etode/leptidea_wolbachia_orthofinder/ -a $threads -t $threads && touch orthofinder.$SLURM_JOB_ID.DONE || touch orthofinder.$SLURM_JOB_ID.FAILED
