#!/bin/bash -l

#### MAIN ####
conda init && conda activate supercrunch && \
mkdir -p supermatrix && \
python Concatenation.py -i renamed_alns/ -o supermatrix/ --informat fasta --outformat fasta -s dash && \

# Fix partitions file format for IQTREE
tail -n +2 supermatrix/Data_Partitions.txt > tmp.txt && mv tmp.txt supermatrix/Data_Partitions.txt && \
sed -i 's/;//g' supermatrix/Data_Partitions.txt && \
sed -Ei 's/(.+)/DNA, \1/g' supermatrix/Data_Partitions.txt && \
touch supercrunch.$SLURM_JOB_ID.DONE || touch supercrunch.$SLURM_JOB_ID.FAILED
