#!/bin/bash -l

#### MAIN ####
# Create kinfin config file
echo '#IDX,TAXON' > config.txt && sed 's/: /,/g' SpeciesIDs.txt >> config.txt

# Run kinfin to get SCO found in at least XX% of the species
kinfin -g Orthogroups.txt -c config.txt -s SequenceIDs.txt --target_count 1 --target_fraction 0.95 --min 0 --max 1 -o kinfin_95_
kinfin -g Orthogroups.txt -c config.txt -s SequenceIDs.txt --target_count 1 --target_fraction 0.90 --min 0 --max 1 -o kinfin_90_
kinfin -g Orthogroups.txt -c config.txt -s SequenceIDs.txt --target_count 1 --target_fraction 0.98 --min 0 --max 1 -o kinfin_98_
