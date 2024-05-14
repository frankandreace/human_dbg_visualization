#!/bin/bash

#CHR * from both CHM13 and 2 HAPLOTYPES FROM T2T HG002
chromosome="chr17"

# STEP 1: SELECT THE CHROMOSOME YOU WANT FROM CHM13 AND MASK THE CHROMOSOME FROM REPETITIONS
if [ ! -f ../data/sequences/chm13v2.0_$chromosome.fa ]; then ./mask_genome.sh ../data/sequences/chm13v2.0.fa ../data/bedfiles/chm13_repeat_regions.txt ../data/sequences/chm13v2.0_$chromosome.fa $chromosome ; fi

# STEP 2: EXTRACT THE 2 CHROMOSOMES FROM HG002
if [ ! -f ../data/sequences/hg002_maternal_$chromosome.fa ]; then ./get_chromosome.sh ../data/sequences/hg002v1.0.1.fasta ../data/sequences/hg002_maternal_$chromosome.fa ${chromosome}_MATERNAL ; fi
if [ ! -f ../data/sequences/hg002_paternal_$chromosome.fa ]; then ./get_chromosome.sh ../data/sequences/hg002v1.0.1.fasta ../data/sequences/hg002_paternal_$chromosome.fa ${chromosome}_PATERNAL ; fi

# STEP 3: ALIGN THEM TO CHM13 CHROMOSOME
if [ ! -f ../data/alignments/aln_hg002_${chromosome}_maternal.paf ]; then minimap2 -cx asm5 -t16 --secondary=no ../data/sequences/chm13v2.0_$chromosome.fa ../data/sequences/hg002_maternal_$chromosome.fa > ../data/alignments/aln_hg002_${chromosome}_maternal.paf ; fi
if [ ! -f ../data/alignments/aln_hg002_${chromosome}_paternal.paf ]; then minimap2 -cx asm5 -t16 --secondary=no ../data/sequences/chm13v2.0_$chromosome.fa ../data/sequences/hg002_paternal_$chromosome.fa > ../data/alignments/aln_hg002_${chromosome}_paternal.paf ; fi

# STEP 4: PROCESS ALIGNMENT FILE INTO BEDFILE REGION
pypy3 paf_to_bed.py ../data/alignments/aln_hg002_${chromosome}_maternal.paf > hg002__${chromosome}_maternal_ranges.bed
pypy3 paf_to_bed.py ../data/alignments/aln_hg002_${chromosome}_paternal.paf > hg002__${chromosome}_paternal_ranges.bed

# STEP 5: MASK REGIONS NOT IN BEDFILE
bedtools maskfasta  -fi ../data/sequences/hg002_maternal_$chromosome.fa -bed hg002__${chromosome}_maternal_ranges.bed -fo ../data/sequences/hg002_maternal_$chromosome.masked.fa
bedtools maskfasta  -fi ../data/sequences/hg002_paternal_$chromosome.fa -bed hg002__${chromosome}_paternal_ranges.bed -fo ../data/sequences/hg002_paternal_$chromosome.masked.fa

# STEP 6: BUILD GRAPH
echo "../data/sequences/chm13v2.0_$chromosome.fa" > ../data/sequences/hg002_$chromosome.fof
echo "../data/sequences/hg002_maternal_$chromosome.masked.fa" >> ../data/sequences/hg002_$chromosome.fof
echo "../data/sequences/hg002_paternal_$chromosome.masked.fa" >> ../data/sequences/hg002_$chromosome.fof

klen=801
ggcat build -l ../data/sequences/hg002_$chromosome.fof -o ../data/unitigs/unitigs_chm13_gh002_${chromosome}_k$klen.fa -j 8 -s 1 -k $klen -e

./convertToGfa.sh ../data/unitigs/unitigs_chm13_gh002_${chromosome}_k$klen.fa ../data/gfa/unitigs_chm13_gh002_${chromosome}_k$klen.gfa $klen

# MAP UNITIGS TO THE REFERENCE
./map_utgs_to_reference.sh ../data/sequences/chm13v2.0_${chromosome}.fa ../data/unitigs/unitigs_chm13_gh002_${chromosome}_k$klen.fa ../data/processed/unitigs_chm13_hg002_${chromosome}_k$klen.tsv

# COLOR THE GFA WITH RELATIVE POSITION IN THE CHROMOSOME
./color_gfa.sh ../data/gfa/unitigs_chm13_gh002_${chromosome}_k$klen.gfa ../data/processed/unitigs_chm13_gh002_${chromosome}_k$klen.tsv ../data/gfa/unitigs_chm13_gh002_position_${chromosome}_k$klen.gfa