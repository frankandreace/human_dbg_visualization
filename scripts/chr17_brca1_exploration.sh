#!/bin/bash

### MAPPING FREE APPROACH TO VARIATION EXPLORATION OF BRCA1 EXONS IN DIFFERENTIAL ANALYSIS BETWEEN POSITIVE AND CONTROL SAMPLES FOR CANCER

#CHR 17 (CONTAINING BRCA1) from both CHM13 and 2 HAPLOTYPES FROM T2T HG002
chromosome="chr17"
klen=31
max_threads=8

### STEP 1: GENERATE REFERENCE DBG FOR CHROMOSOME 17. ###

# STEP 1a: SELECT THE CHROMOSOME YOU WANT FROM CHM13 AND MASK THE CHROMOSOME FROM REPETITIONS
if [ ! -f ../data/sequences/chm13v2.0_$chromosome.fa ]; then ./mask_genome.sh ../data/sequences/chm13v2.0.fa ../data/bedfiles/chm13_repeat_regions.txt ../data/sequences/chm13v2.0_$chromosome.fa $chromosome ; fi

# STEP 1b: EXTRACT THE 2 CHROMOSOMES FROM HG002
if [ ! -f ../data/sequences/hg002_maternal_$chromosome.fa ]; then ./get_chromosome.sh ../data/sequences/hg002v1.0.1.fasta ../data/sequences/hg002_maternal_$chromosome.fa ${chromosome}_MATERNAL ; fi
if [ ! -f ../data/sequences/hg002_paternal_$chromosome.fa ]; then ./get_chromosome.sh ../data/sequences/hg002v1.0.1.fasta ../data/sequences/hg002_paternal_$chromosome.fa ${chromosome}_PATERNAL ; fi

# STEP 1c: ALIGN THEM TO CHM13 CHROMOSOME
if [ ! -f ../data/alignments/aln_hg002_${chromosome}_maternal.paf ]; then minimap2 -cx asm5 -t16 --secondary=no ../data/sequences/chm13v2.0_$chromosome.fa ../data/sequences/hg002_maternal_$chromosome.fa > ../data/alignments/aln_hg002_${chromosome}_maternal.paf ; fi
if [ ! -f ../data/alignments/aln_hg002_${chromosome}_paternal.paf ]; then minimap2 -cx asm5 -t16 --secondary=no ../data/sequences/chm13v2.0_$chromosome.fa ../data/sequences/hg002_paternal_$chromosome.fa > ../data/alignments/aln_hg002_${chromosome}_paternal.paf ; fi

# STEP 1d: PROCESS ALIGNMENT FILE INTO BEDFILE REGION
if [ ! -f hg002_${chromosome}_maternal_ranges.bed ]; then pypy3 paf_to_bed.py ../data/alignments/aln_hg002_${chromosome}_maternal.paf > hg002_${chromosome}_maternal_ranges.bed ; fi
if [ ! -f hg002_${chromosome}_paternal_ranges.bed ]; then pypy3 paf_to_bed.py ../data/alignments/aln_hg002_${chromosome}_paternal.paf > hg002_${chromosome}_paternal_ranges.bed ; fi

# STEP 1e: MASK REGIONS NOT IN BEDFILE
if [ ! -f ../data/sequences/hg002_maternal_$chromosome.masked.fa ]; then bedtools maskfasta  -fi ../data/sequences/hg002_maternal_$chromosome.fa -bed hg002_${chromosome}_maternal_ranges.bed -fo ../data/sequences/hg002_maternal_$chromosome.masked.fa ; fi
if [ ! -f ../data/sequences/hg002_paternal_$chromosome.masked.fa ]; then bedtools maskfasta  -fi ../data/sequences/hg002_paternal_$chromosome.fa -bed hg002_${chromosome}_paternal_ranges.bed -fo ../data/sequences/hg002_paternal_$chromosome.masked.fa ; fi

# STEP 1f: BUILD GRAPH
if [ ! -f ../data/sequences/hg002_$chromosome.fof ]; then 
    echo "../data/sequences/chm13v2.0_$chromosome.fa" > ../data/sequences/hg002_$chromosome.fof
    echo "../data/sequences/hg002_maternal_$chromosome.masked.fa" >> ../data/sequences/hg002_$chromosome.fof
    echo "../data/sequences/hg002_paternal_$chromosome.masked.fa" >> ../data/sequences/hg002_$chromosome.fof
fi

if [ ! -f ../data/unitigs/unitigs_chm13_gh002_${chromosome}_k$klen.fa ]; then ggcat build -l ../data/sequences/hg002_$chromosome.fof -o ../data/unitigs/unitigs_chm13_gh002_${chromosome}_k$klen.fa -j 8 -s 1 -k $klen -e ; fi

### STEP 2: INJECT UNITIGS FROM SAMPLES INTO THE CHR17 GRAPH ###

# STEP 2a: extrapolate list of input samples for GGCAT / extract compressed files / ecc

# generate file with files to give to ggcat
echo  "../data/unitigs/unitigs_chm13_gh002_${chromosome}_k$klen.fa" > ../data/sequences/final_genomes_input.fof
cat "../data/sequences/1kgenomes_10samples.txt" >> ../data/sequences/final_genomes_input.fof
# extract zst file and compress into gzip for brca1 and brca2 genomes
cat "../data/sequences/brca1_10samples.txt" | xargs -I {} ./unzstd_gzip.sh {} ../data/sequences/final_genomes_input.fof
cat "../data/sequences/brca2_5samples.txt" | xargs -I {} ./unzstd_gzip.sh {} ../data/sequences/final_genomes_input.fof

# STEP 2b: generate dbg of chr17 (and everything else for samples)
if [ ! -f ../data/unitigs/unitigs_chm13_gh002_${chromosome}_k$klen.fa ]; then ggcat build  -j $max_threads -s 1 -k $klen -e -c -l ../data/sequences/final_genomes_input.fof -o ../data/unitigs/unitigs_case_control_${chromosome}_k$klen.fa ; fi

# STEP 2c: test on exon 10 of BRCA1
test_file=../data/genes/BRCA1_exon10.fa

### step 2d- : For every interesting exon 
#                        - query it in the dbg

ggcat dump-colors ../data/unitigs/unitigs_case_control_${chromosome}_k$klen.colors.dat ../data/unitigs/unitigs_case_control_${chromosome}_k$klen.colors.jsonl
ggcat query --colors -k $klen -j $max_threads ../data/unitigs/unitigs_case_control_${chromosome}_k$klen.fa $test_file -o ../data/processed/unitigs_in_exon

#                        - flag unitigs that are in the reference
# to do so, I shall parse the jsonl file and detect all lines that contain a specific element

#                        - get the connected components containing those untigs

#                        - color unitigs based on the sample (cancer/1kgenomes/reference?-should be healthy-useful to flag non-cancerous mutations)
#                           how to flag unitigs in both? Or displaying 5 different images   
#                                           * reference path
#                                           * healthy path                                           
#                                           * ONLY healthy utgs path
#                                           * cancer path
#                                           * ONLY CANCER path

#                        - display the graphs stiched into a single pdf for every exon


### STEP 2d: use kmdiff to flag interesting kmers differences?
