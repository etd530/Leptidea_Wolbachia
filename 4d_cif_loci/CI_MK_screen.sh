#!/bin/bash -l

conda init && conda activate emboss
set -euo pipefail

#### ARGS ####
if [ "$#" -ne 11 ]; # checking number of arguments is OK
then echo "Usage: $0 <genome> <infolder> <loci_ref> <tmp_dir> <outdir> <threads> <max_evalue> <qlen_per> <prot_db> <proteome_annot> <proteome_fasta>" && exit;
fi;

genome=$1 # genome where we need to find the loci
genome_pre=$(basename $genome .fasta | cut -f1,2,3,4 -d'.') # prefix of the genome name to use in the output files
infolder=$2 # folder where the loci reference files are
loci_ref=$3 # reference sequences for the loci to look for
tmp_dir=$4
outdir=$5
t=$6 # number of threads to use
max_eval=$7 # e-value threshold for the tblastn search
qlen_per=$8 # percent of length of query that aligns to filter out (in %, NOT in proportion, e.g. 60 and NOT 0.6)
prot_db=$9 # blast database to use for the validation. Has to be protein DB and made prior to running the script (you may add the makeblastdb command if you wish)
proteome_annot=${10} # proteome annotation in GFF from the annotation of the query genome to compare the blast hits against, to check how likely they are to be functional (FULL PATH)
proteome_fasta=${11} # FASTA file containing the annotated proteeome of the query genome to extract the proteins that overlap with our hits

# Create tmp dir if it does not exist
mkdir -p "${tmp_dir}" && \

# Create output dir if it does not exist
mkdir -p "${outdir}" && \

# Make blast database from the query genome
makeblastdb -dbtype nucl -in "${genome}" && echo "Blast database created for ${genome}" && \

# Run tblastn of reference loci to look for against query genome and sort result by evalue
tblastn -query "${infolder}/${loci_ref}" -out "${tmp_dir}/${loci_ref}.vs.${genome_pre}.out" -num_threads "${t}" -db_gencode 11 -max_hsps 10 -db "${genome}" \
-outfmt '6 qseqid sseqid sstart send pident qcovhsp evalue bitscore' && \
sort -gk5 "${tmp_dir}/${loci_ref}.vs.${genome_pre}.out" > "${tmp_dir}/${loci_ref}.vs.${genome_pre}.sorted.out" && echo "tblastn results sorted for ${loci_ref} vs ${genome_pre}" && \

# Filter out those with too low percent of query aligned and too high e-value
awk -v p="${qlen_per}" -v evalue=${max_eval} 'BEGIN{ OFS=FS="\t"; CONVFMT="%.3f" } { if($6>p && $7<evalue){print} }' "${tmp_dir}/${loci_ref}.vs.${genome_pre}.sorted.out" > \
"${tmp_dir}/${loci_ref}.vs.${genome_pre}.sorted.filtered.out" && \
echo "Filtered results for ${loci_ref} vs ${genome_pre}" && \

# Check that there are filtered hits or else exit the script
hit_num=$(wc -l < "${tmp_dir}/${loci_ref}.vs.${genome_pre}.sorted.filtered.out") && \
if (( $hit_num == 0 )); then echo "No hits obtained for ${loci_ref} in ${genome_pre}" && exit; else echo "${hit_num} hits obtained for ${loci_ref} in ${genome_pre}."; fi && \

# Extract the regions that hit
rm -f ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta && \
echo "Extracting sequences for regions on ${genome_pre} that hit to ${loci_ref} reference sequences..." && \
while read hit; do 
        start=`echo $hit | cut -f3 -d" "`; # faidx gets both 0 and 1 as the first base
        end=`echo $hit | cut -f4 -d" "`;
        chr=`echo $hit | cut -f2 -d" "`;
        homolog=`echo $hit | cut -f1 -d" "`;
        echo ">${chr}|${start}_${end}|${homolog}-like" >> ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta;
        if (( $start < $end )); then
                samtools faidx "${genome}" ${chr}:${start}-${end} | grep -v '^>' >> ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta;
        else
                samtools faidx "${genome}" ${chr}:${end}-${start} | grep -v '^>' >> ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta;
        fi;
done < ${tmp_dir}/${loci_ref}.vs.${genome_pre}.sorted.filtered.out && \

# Check there are hits or else exit the script
hit_num=$(grep '^>' ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta | wc -l) && \
if (( $hit_num == 0 )); then echo "No hits obtained for ${loci_ref} in ${genome_pre}"; exit; else echo "${hit_num} hits obtained for ${loci_ref} in ${genome_pre}."; fi && \

# Back-blast them against a reference proteome of a genome with the desired locus to confirm it hits best to that one
# makeblastdb -dbtype prot -in ${prot_db} && \  now this is done once outside the script
echo "Running blastx search..." && \
blastx -query ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta -out ${tmp_dir}/${genome_pre}.${loci_ref}.putative.vs.prot_db.out -query_gencode 11 \
-outfmt '6 qseqid sseqid sstart send slen length pident qcovs evalue bitscore frames qseq' -num_threads "${t}" -max_hsps 10 -db ${prot_db} && \
sort -gk9 "${tmp_dir}/${genome_pre}.${loci_ref}.putative.vs.prot_db.out" > "${tmp_dir}/${genome_pre}.${loci_ref}.putative.vs.prot_db.sorted.out" && \
awk -v evalue=${max_eval} 'BEGIN{ OFS=FS="\t"; CONVFMT="%.3f" } { if($9<evalue){print} }' "${tmp_dir}/${genome_pre}.${loci_ref}.putative.vs.prot_db.sorted.out" > \
"${tmp_dir}/${genome_pre}.${loci_ref}.putative.vs.prot_db.sorted.filtered.out" && \

# Make list of protein ID of the target loci to check if they are in the back-blast validation results
re=`grep '^>' ${infolder}/${loci_ref} | cut -f4 -d'.' | paste -s -d ' '` && echo "${re}" && \

# For each of the candidates, check if it hits to the expected protein better than to others and if so, keep these as validated
rm -f ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.IDs.txt && rm -f ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.fasta && rm -f ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.protein.fasta && \
rm -f ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.out && \
echo "Validating putative hits for ${loci_ref} in ${genome_pre} by back-blasting against ${prot_db}..." && \
while read line; do 
        if echo $line | grep -q '^>'; then 
                id=`echo $line | sed -E 's/^>//g'`;
                echo "Evaluating ${id} for ${loci_ref} in ${genome_pre}...";
                grep -F "${id}" ${tmp_dir}/${genome_pre}.${loci_ref}.putative.vs.prot_db.sorted.filtered.out > ${tmp_dir}/${genome_pre}.${loci_ref}.blast_subset.out;
                hit_pos=$(awk -v values="$re" '{n=split(values, arr, " "); for (i=1;i<=n;i++) {if (index($2, arr[i]) > 0) {print NR; exit}}}' ${tmp_dir}/${genome_pre}.${loci_ref}.blast_subset.out)
                echo "$hit_pos";
                if [[ "$hit_pos" == "1" ]]; then
                        echo  ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta;
                        echo "${id} has ${loci_ref} as the best hit. Adding it to the validated loci list.";
                        samtools faidx ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta "${id}" >> ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.fasta;
                        hit_frame=`head -n1 ${tmp_dir}/${genome_pre}.${loci_ref}.blast_subset.out | cut -f11 | cut -f1 -d'/'`
                        if (( ${hit_frame} >= 0 )); then
                                echo "strand is forward with frame ${hit_frame}";
                        else
                                echo "strand is reverse with frame ${hit_frame}";
                        fi;
                        transeq -sequence ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.fasta -outseq ${tmp_dir}/${genome_pre}.${loci_ref}.tmp -frame ${hit_frame} -table 11 && cat ${tmp_dir}/${genome_pre}.${loci_ref}.tmp >> ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.protein.fasta
                        head -n1 ${tmp_dir}/${genome_pre}.${loci_ref}.blast_subset.out >> ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.out;
                        echo "$id" >> ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.IDs.txt;
                else
                        echo "Hit to ${re} is not the first one for ${loci_ref} in ${genome}";
                fi;
        fi;
done < ${tmp_dir}/${genome_pre}.${loci_ref}.putative.fasta && \
rm -f ${tmp_dir}/${genome_pre}.${loci_ref}.blast_subset.out;
rm -f ${tmp_dir}/${genome_pre}.${loci_ref}.tmp;

# Assert there are validated hits, else exit the script
if [ -s ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.fasta ]; then
        validated_count=$(grep '^>' ${tmp_dir}/${genome_pre}.${loci_ref}.validated_loci.fasta | wc -l)
        echo "${validated_count} validated loci found for ${loci_ref} in ${genome_pre}."
else
        echo "No validated hits obtained for ${loci_ref} in ${genome_pre}" && exit;
fi && \

# Concatenate all validated loci in a single fasta
rm -f ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.fasta;
for file in ${tmp_dir}/*validated_loci.fasta;
do cat $file >> ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.fasta;
done;

validated_count=$(grep '^>' ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.fasta | wc -l)
echo "${validated_count} validated loci found for ${loci_ref} in ${genome_pre}.";

# Concatenate all validated loci in a single blast output
rm -f ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.out && \
for file in ${tmp_dir}/*validated_loci.out;
do cat $file >> ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.out;
done;

# Build an approximate GFF for each validated locus with the coordinates of the original blast hit
rm -f ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.gff;
echo "Building GFF for validated loci in ${genome_pre}..." && \
echo '##gff-version 3' > ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.gff;
while read line; do
        ctg=$(echo "$line" | cut -f1 -d' ' | cut -d'|' -f1)
        coords=$(echo "$line" | cut -f1 -d' ' | cut -d'|' -f2)
        start=$(echo "$coords" | cut -f1 -d'_')
        end=$(echo "$coords" | cut -f2 -d'_')
        frame=`echo $line | cut -f11 -d' ' | cut -f1 -d'/'`;
        # assert start and end are numbers
        if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then
                echo "ERROR: non-numeric coordinates parsed from: $line" >&2 && exit 1
        fi
        # Fix start and end according to frame of the hit (NOTE: this assumes that the sequence length is divisible by 3 so it is only approximate!)
        if ((  $frame == 2 )); then
                start=$(( $start + 1 ));
                end=$(( $end - 2 ));
        elif (( $frame == 3 )); then
                start=$(( $start + 2 ));
                end=$(( $end - 1 ));
        elif (( $frame == -2 )); then
                start=$(( $start + 2 ));
                end=$(( $end - 1 ));
        elif (( $frame == -3 )); then
                start=$(( $start + 1 ));
                end=$(( $end - 2 ));
        fi;
        if (( $start < $end )); then
                strand='+';
        else strand='-';
        fi;
        comment=`echo $line | cut -f1 -d' '`;
        comment="${comment};frame_${frame}(1-based)"
        if [[ $strand == '+' ]]; then
                echo -e "${ctg}\t.\tCDS_partial\t${start}\t${end}\t.\t${strand}\t.\tID=${comment}" >> ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.gff;
        else
                echo -e "${ctg}\t.\tCDS_partial\t${end}\t${start}\t.\t${strand}\t.\tID=${comment}" >> ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.gff;
        fi;
done < ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.out;
set +euo pipefail && conda activate gfftk && set -euo pipefail && echo "Sorting GFF for validated loci in ${genome_pre}..." && \
gfftk sort -g ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.gff -o ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.gff && \

# Find overlap between annotated hits and annotated proteins from Prokka
echo "Finding overlap between validated loci and annotated proteins in ${genome_pre}..." && \
egrep -v '^>' ${proteome_annot} | egrep -v '^[ATCGN]+' | bedtools intersect -a stdin -b ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.gff -wb -s > ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.intersected.gff

# Merge overlapping features
echo "Merging overlapping features in ${genome_pre}..." && \
bedtools merge -i ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.gff -s -c 7,9 -o distinct > ${tmp_dir}/${genome_pre}.tmp && \
gawk '{print $1"\t.\tCDS_partial\t"$2+1"\t"$3"\t.\t"$4"\t.\t"$5}' ${tmp_dir}/${genome_pre}.tmp > ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.gff && rm -f ${tmp_dir}/${genome_pre}.tmp && \

# Create GFF with only those features largely overlapping with Prokka-annotated proteins in the same strand, and thus likely functional
# (Note: BEDtools inserect works with GFF too)
# NOTE that the overlap is hardcoded to 60% (-f 0.60)
# -wb only reports the feature in file B, in this case our hits
# -s means consider overlaps only on the same strand
egrep -v '^>' ${proteome_annot} | egrep -v '^[ATCGN]+' | bedtools intersect -a stdin -b ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.gff -f 0.6 -wb -s > ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.functional.RAW.gff && \

# BEDtools gives as a "double" GFF with the entries of file A and the ones in file B one after each other in a single line so we keep the second half, which contains the B file features (i.e. the blast hits)
cut -f10- ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.functional.RAW.gff | uniq > ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.functional.CLEAN.gff && \

# From the "double" GFF, extract the IDs of the Bakta annotated proteins that overlap with our hits, then extract those proteins into separate fasta files from the proteome file
cut -f -9 ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.functional.RAW.gff | egrep -o 'ID=[A-Z]+_[0-9]+;' | sed -E 's/;//g' | cut -f2 -d'=' | sort | uniq > ${tmp_dir}/${genome_pre}.tmp && \
while read id; do
        grep "${id}" ${proteome_fasta} | sed -E 's/>//g' >> ${tmp_dir}/${genome_pre}.CI_MK_loci.bakta_IDs.txt;
done < ${tmp_dir}/${genome_pre}.tmp
rm -f ${tmp_dir}/${genome_pre}.tmp
# Assert that the IDs file is not empty, else exit the script
if [ ! -s ${tmp_dir}/${genome_pre}.CI_MK_loci.bakta_IDs.txt ]; then
    echo "No Bakta IDs found for validated loci in ${genome_pre}. Exiting script." && exit;
else
    echo "Bakta IDs found for validated loci in ${genome_pre}."
fi

sort -u ${tmp_dir}/${genome_pre}.CI_MK_loci.bakta_IDs.txt > ${tmp_dir}/${genome_pre}.tmp && mv ${tmp_dir}/${genome_pre}.tmp ${tmp_dir}/${genome_pre}.CI_MK_loci.bakta_IDs.txt && \
samtools faidx ${proteome_fasta} -r ${tmp_dir}/${genome_pre}.CI_MK_loci.bakta_IDs.txt > ${tmp_dir}/${genome_pre}.CI_MK_loci.bakta_proteins.fasta && \

# Create GFF with those features from our BLAST results that are not in the functional subset, so the ones that could correspond to pseudogenised sequences
bedtools intersect -b ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.functional.CLEAN.gff -a ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.gff -v -wa > ${tmp_dir}/${genome_pre}.CI_MK_loci.validated.sorted.merged.NON_functional.gff && \

# Sync all results to the output folder
rsync -avhLP ${tmp_dir}/* ${outdir}/ && echo "All results synced to ${outdir}. Script completed successfully."
