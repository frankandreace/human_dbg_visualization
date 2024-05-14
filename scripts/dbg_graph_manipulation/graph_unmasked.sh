#!/bin/bash
klen=$1
ggcat build ../data/sequences/chr18_chm13_hg002mp.fa -o ../data/unitigs/unitigs_chr18.fa -j 9 -s 1 -k $klen -e

./convertToGfa.sh ../data/unitigs/unitigs_chr18.fa ../data/gfa/unitigs_chr18.gfa $klen
# MAP UNITIGS TO THE REFERENCE
./map_utgs_to_reference.sh ../data/sequences/chr18.fa ../data/unitigs/unitigs_chr18.fa ../data/processed/unitigs_chr18.tsv

# COLOR THE GFA WITH RELATIVE POSITION IN THE CHROMOSOME
./color_gfa.sh ../data/gfa/unitigs_chr18.gfa ../data/processed/unitigs_chr18.tsv ../data/gfa/unitigs_chr18_position_$klen.gfa

echo "mv nodes:" && grep -c "mv:" ../data/gfa/unitigs_chr18_position_$klen.gfa
echo "fx nodes:" && grep -c "fx:" ../data/gfa/unitigs_chr18_position_$klen.gfa
echo "Nodes:" && grep -c "^S" ../data/gfa/unitigs_chr18_position_$klen.gfa
echo "Edges:" && grep -c "^L" ../data/gfa/unitigs_chr18_position_$klen.gfa
