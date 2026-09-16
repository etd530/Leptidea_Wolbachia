- matings_CI_t_test.R: script used to evaluate the statistical significance of the difference in hatch rate between matings expected to produce and not produce CI.
- fastp.sh: script used to filter/trim Illumina reads for the WGS data.
- minimap2.vs.wCquin.sh: script used to map the Illumina reads to the wCquin Wolbachia strain and filter them by mapping quality.
- mosdepth.sh: script for evaluated the mean depth and breadth of coverage of Illumina reads across the reference genome of the wCquin Wolbachia strain.
- plot_breadth_vs_cov.R: script for plotting depth vs. breadth of coverage for all samples.

- minimap2.competitive.sh: script to map the Illumina libraries against an exhaustive set of high-quality Wolbachia genomes.
- extract_wolbachia_reads.sh: script to extract the Wolbachia reads from the previous competitive mapping.
- merge_batches.sh: script to merge different sequencing batches coming from the same sample.

- 3d_assembly_wolbachia: contains four folders; spades, spades_filtered, unicycler and unicycler_filtered. Each of them has scripts to assemble Wolbachia genomes from the mapped reads and evaluate the assembly. The script are as follows:
	- spades/spades.sh: script to run the SPAdes assembler.
	- unicycler/unicycler.sh: scipt to run the Unicycler assembler.
	- \*/blobtools.sh: script to run Blobtools and evaluate contamination in the assemblies.
	- \*/extract_wolbachia_ctgs.sh: script to extract the contigs assigned to Wolbachia with blobtools.
	- \*/busco.sh: script to run BUSCO.
	- \*/meryl_merqury.sh: script to run a merquery kmer completeness analysis of the assemblies.
	- \*/bakta.sh: script to run Bakta to annotate the genomes.
	- \*/summarise_assembly_metrics.sh: script to summarise the quality metrics from the previous analyses.

	In addition: scaffoldstats.pl from https://github.com/sujaikumar/assemblage/blob/master/scaffold_stats.pl was also used.

	The script `compare_assemblies.R` was used to compare the SPAdes and Unicycler assemblies and select the best one.


- 4c_orthofinder: contains the scripts required to obtain sets of single-copy orthologs from the Wolbachia assemblies:
	- orthofinder.sh: script to run OrthoFinder to identify orthogroups.
	- extract_fSCOs.sh: script to get the single-copy orthologs found in at least 95% of the samples.
	- kinfin.slurm.sh: script to run kinfin to identify single-copy orthologs present at least in a given percentage of the total number of samples (i.e. 95%).

- 4d_cif_loci: contains a single script, CI_MK_screen.sh, used to screen the Wolbachia draft assemblies for the CIF genes.

- 7_small_phylogeny: contains the scripts to compute the Wolbachia phylogenetic tree
	- mafft.sh: script to align the SCOs using MAFFT.
	- trimal.sh: script to trim the alignments using trimaAL.
	- phi.slurm.sh: script to evaluate intragenic recombination for each orthogroup using PHI test.
	- concatenation.slurm.sh: script to concatenate the aligned loci
	- iqtree.slurm.sh: script to run IQ-TREE
