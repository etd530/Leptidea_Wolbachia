#!/bin/bash -l

# This script runs blobtools, then partitions all reads mapping to contigs of a specified taxonomic assignment (e.g. Wolbachia, but can also be "no-hit",
# i.e. those reads mapping to contigs of uncertain taxonomic assignment), as well as those not mapping to any contig.

# It can map both long reads and short reads in different strategies, to not pass long reads you can pass a zero to the pb_reads arg

#### MODULES ####
module load BLAST+/2.17.0-gompi-2024a        # blast module
module load minimap2/2.30-GCCcore-13.3.0     # minimap2 module
module load SAMtools/1.22.1-GCC-13.3.0       # samtools module
conda activate blobtools       # blobtools conda environment
set -euo pipefail

#### VARS ####
ref_genome=$1
pb_reads=$2
outprefix=$3
interleaved=$4
sr_reads1=$5
sr_reads2=$6
blobtools_outdir=$7
minimap_threads=$8
blast_threads=$9

# Create scratch dir if it does not exist
mkdir -p /scratch/etode/blobtools

# map pacbio reads IF there are any
if [[ "${pb_reads}" != "0" ]]; then
	rm -rf /scratch/etode/blobtools && mkdir -p /scratch/etode/blobtools && minimap2 -t ${minimap_threads} -ax map-pb ${ref_genome} ${pb_reads} | samtools sort -@${minimap_threads} -T /scratch/etode/blobtools/${outprefix}.pb.reads.bam.tmp -o /scratch/etode/blobtools/${outprefix}.pb.reads.bam && samtools index /scratch/etode/blobtools/${outprefix}.pb.reads.bam;
fi

# map illumina reads, considering if they are interleaved or not
if ((${interleaved} == 1)); then 
	echo "Starting mapping of interleaved illumina reads..."
	mkdir -p /scratch/etode/blobtools && minimap2 -t ${minimap_threads} -ax sr ${ref_genome} ${sr_reads1} | samtools sort -@${minimap_threads} -T /scratch/etode/blobtools/${outprefix}.sr_reads.bam.tmp -o /scratch/etode/blobtools/${outprefix}.sr_reads.bam && samtools index /scratch/etode/blobtools/${outprefix}.sr_reads.bam && echo "Mapping done!";
else
	echo "Starting mapping of non-interleaved illumina reads..."
	mkdir -p /scratch/etode/blobtools && minimap2 -t ${minimap_threads} -ax sr ${ref_genome} ${sr_reads1} ${sr_reads2} | samtools sort -@${minimap_threads} -T /scratch/etode/blobtools/${outprefix}.sr_reads.bam.tmp -o /scratch/etode/blobtools/${outprefix}.sr_reads.bam && samtools index /scratch/etode/blobtools/${outprefix}.sr_reads.bam && echo "Mapping done!";
fi

# blast assembly contigs
echo "Starting BLASTn run..."
mkdir -p /scratch/etode/blobtools && blastn -query ${ref_genome} -out /scratch/etode/blobtools/${outprefix}.vs.nt.out -num_threads ${blast_threads} -max_target_seqs 10 -max_hsps 1 -db nt -evalue 1e-25 -outfmt '6 qseqid staxids bitscore std' && echo "BLASTn run completed!"# we keep it on scratch

# Run BlobTools create
if [[ "${pb_reads}" != "0" ]]; then
	mkdir -p /scratch/etode/blobtools && \
		blobtools create -i ${ref_genome} \
		-t /scratch/etode/blobtools/${outprefix}.vs.nt.out \
		-b /scratch/etode/blobtools/${outprefix}.pb.reads.bam \
		-b /scratch/etode/blobtools/${outprefix}.sr_reads.bam \
		-o /scratch/etode/blobtools/${outprefix} \
		--nodes /sw/data/ncbi_taxonomy/latest/nodes.dmp \
		--names /sw/data/ncbi_taxonomy/latest/names.dmp;
else
	echo "Running blobtools create..." && \
	mkdir -p /scratch/etode/blobtools && \
		blobtools create -i ${ref_genome} \
		-t /scratch/etode/blobtools/${outprefix}.vs.nt.out \
		-b /scratch/etode/blobtools/${outprefix}.sr_reads.bam \
		-o /scratch/etode/blobtools/${outprefix} \
		--nodes /sw/data/ncbi_taxonomy/latest/nodes.dmp \
		--names /sw/data/ncbi_taxonomy/latest/names.dmp && \
	echo "Blobtools create completed!"
fi

# Run BlobTools view and plot
echo "Running blobtools view and plot..." && \
blobtools view -i /scratch/etode/blobtools/${outprefix}.blobDB.json \
-o /scratch/etode/blobtools/ -r all --hits && \
blobtools plot -i /scratch/etode/blobtools/${outprefix}.blobDB.json \
-o /scratch/etode/blobtools/ -r order && \
echo "Blobtools completed! rsync of outfile files..."

# create outdir if it does not exist and rsync blobtools plots, JSON database and table to corresponding directory
mkdir -p ${blobtools_outdir} && \
rsync -avhLP /scratch/etode/blobtools/${outprefix}* ${blobtools_outdir} && \
#rsync -avhP /scratch/etode/blobtools/${outprefix}*.blobDB.table.txt ${blobtools_outdir} && \
#rsync -avhP /scratch/etode/blobtools/${outprefix}*.png ${blobtools_outdir} && \
#rsync -avhP /scratch/etode/blobtools/${outprefix}*.blobDB.json ${blobtools_outdir}
# empty the scratch dir
#rm -rf /scratch/etode/blobtools && \
echo "Script completed!"

### END ###
