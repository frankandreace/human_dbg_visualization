
# MAP UNITIGS TO THE REFERENCE
./map_utgs_to_reference.sh ../data/sequences/chr18.fa ../data/unitigs/unitigs_chr18_masked.fa ../data/processed/unitigs_chr18_masked_position.tsv

# COLOR THE GFA WITH RELATIVE POSITION IN THE CHROMOSOME
./color_gfa.sh ../data/gfa/unitigs_chr18_masked.gfa ../data/processed/unitigs_chr18_masked_position.tsv ../data/gfa/chr18_masked_positioned.gfa