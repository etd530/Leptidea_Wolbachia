#!/usr/bin/env bash

#### MODULES ####
set -euo pipefail

#### MAIN ####
echo -e "sample\tassembler\tspan\tnumber of contigs\tN50\tlongest scaffold\tGC%\tBUSCO S\tBUSCO D\tBUSCO F\tBUSCO M\ttRNA count\trRNA count\tCDS count\tHypothetical CDS\tProteome span\tkmer completeness\tkmer QV" > unicycler_assemblies_filtered_summary.tsv
for file in assemblies/*.unicycler_filtered.asm.fasta; do
	sample_prefix=$(basename $file | cut -f1,2,3,4 -d'.')
	echo $sample_prefix
	assembler='Unicycler'
	if [ -s scaffoldstats/$sample_prefix.scaffoldstats.txt ]; then
		span=$(grep -A7 'For scaffolds longer than 1000 bp' scaffoldstats/$sample_prefix.scaffoldstats.txt | grep 'Span' | cut -f2)
		ctg_n=$(grep -A7 'For scaffolds longer than 1000 bp' scaffoldstats/$sample_prefix.scaffoldstats.txt | grep -P 'Num\t' | cut -f2)
		n50=$(grep -A7 'For scaffolds longer than 1000 bp' scaffoldstats/$sample_prefix.scaffoldstats.txt | grep '\bN50' | cut -f2)
		gc=$(grep -A7 'For scaffolds longer than 1000 bp' scaffoldstats/$sample_prefix.scaffoldstats.txt | grep 'GC' | cut -f2)
		longest_scf=$(grep 'LongestScaffold' scaffoldstats/$sample_prefix.scaffoldstats.txt | cut -f2)
	else
		span="NA" && ctg_n="NA" && n50="NA" && gc="NA" && longest_scf="NA"
	fi
	if [ -s busco/$sample_prefix.busco_rickettsiales_odb12/*txt ]; then
		busco_sc=$(grep 'single-copy' busco/$sample_prefix.busco_rickettsiales_odb12/*txt | cut -f2)
		busco_d=$(grep 'duplicated' busco/$sample_prefix.busco_rickettsiales_odb12/*txt | cut -f2)
		busco_f=$(grep 'Fragmented' busco/$sample_prefix.busco_rickettsiales_odb12/*txt | cut -f2)
		busco_m=$(grep 'Missing' busco/$sample_prefix.busco_rickettsiales_odb12/*txt | cut -f2)
	else
		busco_sc="NA" && busco_d="NA" && busco_f="NA" && busco_m="NA"
	fi
	if [ -s bakta/$sample_prefix.bakta/$sample_prefix.tsv ]; then
		trna_count=$(grep -P "\ttRNA\t" bakta/$sample_prefix.bakta/$sample_prefix.tsv | wc -l || true)
		rrna_count=$(grep -P "\trRNA\t" bakta/$sample_prefix.bakta/$sample_prefix.tsv | wc -l || true)
		total_cds=$(grep -c '^>' bakta/$sample_prefix.bakta/$sample_prefix.faa || true)
		hypothetical_cds=$(grep -c '^>' bakta/$sample_prefix.bakta/$sample_prefix.hypotheticals.faa || true)
		proteome_span=$(grep -v '^>' bakta/$sample_prefix.bakta/$sample_prefix.faa | sed -Ez 's/\n//g' | wc -c || true)
	else
		trna_count="NA" && rrna_count="NA" && total_cds="NA" && hypothetical_cds="NA" && proteome_span="NA"
	fi
	if [ -s merqury/$sample_prefix.merqury.completeness.stats ]; then
		kmer_comp=$(cut -f5 merqury/$sample_prefix.merqury.completeness.stats)
		kmer_qv=$(cut -f4 merqury/$sample_prefix.merqury.qv)
	else
		kmer_comp="NA"
		kmer_qv="NA"
	fi
	echo -e "$sample_prefix\t$assembler\t$span\t$ctg_n\t$n50\t$longest_scf\t$gc\t$busco_sc\t$busco_d\t$busco_f\t$busco_m\t$trna_count\t$rrna_count\t$total_cds\t$hypothetical_cds\t$proteome_span\t$kmer_comp\t$kmer_qv" >> unicycler_assemblies_filtered_summary.tsv
done
