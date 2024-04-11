#!/bin/bash

# Script Name: position_dbg_generator
# Author: Francesco Andreace
# Date: 9th of April 2024
# Description: bash/awk script to create a position aware unitig dbg in gfa format of a specific (repeat-masked) region of the genome or chromosome from a set of samples.
# Input: 
#   - the desired chromosome or part of the genome, repeat masked
#   - a fof of the set of samples to consider
# Tools dependencies:
#   - minimap2 to select reads
#   - ggcat to build the dbg
# DISCLAIMER: THE SCRIPT CONSIDERS THESE 2 TOOLS (minimap2, ggcat) ARE ALREADY INSTALLED IN YOUR SISTER / CLUSTER

SCRIPT_NAME="position_dbg_generator" #$(basename $0)

#SETTING DEFAULT PARAMETERS
DEFAULT_KSIZE=61
DEFAULT_THREADS=8
DEFAULT_MIN_COUNT=1
DEFAULT_OUTDIR=output

USAGE=$'\nUsage: '"${SCRIPT_NAME}"' [-k KMER-SIZE] [-t NUM-THREADS] [-c MIN-COUNT] [-o OUT-DIR] <input_region.fa> <input_seqfile.seq>

Arguments:
     -h              print this help and exit
     -k              kmer size for ggcat and kmtricks (default:31)
     -t              number of cores (default:4)
     -c              minimum count of kmers to be retained (default:1)
     -o              output directory (default:output)


Positional arguments:
     <input_fasta>         input region (fasta)
     <input_file_of_files>         list of unitigs/assemblies (txt)
'


#PARSING INPUT OPTIONS
k_len=$DEFAULT_KSIZE
thr=$DEFAULT_THREADS
min_count=$DEFAULT_MIN_COUNT
output_dir=$DEFAULT_OUTDIR

while getopts ":hk:t:c:o:" flag; do
   case "${flag}" in
      h) $(>&2 echo "${USAGE}")
         exit 0
         ;;
      k) k_len=${OPTARG}
         ;;
      t) thr=${OPTARG}
         ;;
      o) output_dir=${OPTARG}
         ;;
      c) min_count=${OPTARG}
         ;;
      ?) $(>&2 echo "Error. Option not recognised.\n${USAGE}")
         exit 0
         ;;
    esac
done

#ADDING INPUT FILE AND OUTPUT FOLDER
input_fasta=""
input_fof=""

if [ $# -lt ${OPTIND} ] # + 1
then
    (>&2 echo "ERROR: Wrong number of arguments.")
    (>&2 echo "")
    (>&2 echo "${USAGE}")
    exit 1
fi

input_fasta=${@:$OPTIND:1}
input_fof=${@:$OPTIND+1:1}

# MAP READS FOF WITH MINIMAP2 TO SELECTED REGION / CHROMOSOME / MASKED GENOME AND TAKE OUT ONLY READS MAPPING TO SELECTED FILE 

eho $input_fasta > $input_fof.temp

while IFS= read -r sample; do
    minimap2 -xsr --secondary=no $input_fasta $sample | awk '
    BEGIN { 
    FS=" "
    OFS="\t" 
    ORS="\n"
    curr_mapped_read = -1
    print_line=0
    }
    FNR != NR { exit }
    />/ {
    old_line=$0
    current_read_id=sub(">","",$1)
        while ( curr_mapped_read < current_read_id) {
            if (getline < ARGV[2] > 0) {
                curr_mapped_read = $1
                current_pos = $2
            }
            else { break }
        }
        if ( curr_mapped_read == current_read_id ) { 
            print old_line; print_line=1
            }
        next;
    }
    /!>/ { if (print_line==1) {print $0; print_line=0}
        next;
    }
    ' $sample - > $sample.temp
    echo $sample.temp >> $input_fof.temp

done < $input_fof

# BUILD (C)CDBG WITH GGCAT 
ggcat build -l $input_fof.temp -o $output_dir/unitigs.fa -j $thr -s $DEFAULT_MIN_COUNT -k $k_len

awk '
BEGIN{
        old = "H\tVN:Z:1.0\tks:i:" ARGV[2]
        ks = ARGV[2] - 1
}!/^>/{
        printf "%s", $1
        next
}{
        x = ""
        $1 = substr($1,2)
        for(i=2; i<=NF; i++){
                if($i ~ /^LN/)
                        x="\t" $i "\t" x
                else if($i ~ /^L/){
                        split($i, a, ":")
                        x = x "\nL\t"$1"\t"a[2]"\t"a[3]"\t"a[4]"\t" ks "M"
                }
        }
        printf "%s\nS\t%s\t", old, $1
        old = x
}END{
        print old
}
' < $output_dir/unitigs.fa > $output_dir/unitigs.gfa

minimap2 -xsr --secondary=no $input_fasta $output_dir/unitigs.fa | awk '
    BEGIN { 
    FS="\t" 
    OFS="\t" 
    ORS="\n"
    sum_0=0; sum_60=0; sum_diff=0; count=0 
    }
    { count++
    if ($12 == 0) {sum_0++; print $1, $9, $12} 
    if ($12 == 60) {sum_60++;  print $1, $9, $12}
    if ($12 != 0 && $12 != 60) {sum_diff ++; print $1, $9, $12} 
    } 
    END { 
        print "alignment_score. 0:" sum_0/count " (" sum_0 ") ; 60:" sum_60/count " (" sum_60 ") ; !=: " sum_diff/count " (" sum_diff ")" > "stats.tsv"
        print "total sum: "sum_0+sum_60+sum_diff, " ; counted lines: "count >> "stats.tsv" 
    }
    ' | sort -k2,2n \
    | awk '
    BEGIN {
    FS="\t"
    OFS="\t"
    ORS="\n"
    pos_id=0 
    }
    {
        if ($3 == 60) {print $1, pos_id++, "0"}
        else {print $1, pos_id++, "1"}
    }
    ' |sort -k1,1n | \
awk '
BEGIN {
    FS="\t"
    OFS="\t"
    ORS="\n"
    current_utg_id = -1
    }
    FNR != NR { exit }
    /^S/ {
        old_line=$0
        curr_segment=$2
        while ( curr_segment > current_utg_id) {
            if (getline < ARGV[2] > 0) {
                current_utg_id = $1
                current_utg_pos = $2
                pos_flag=$3
            }
            else { break }
        }
        if ( curr_segment == current_utg_id ) { 
            if (pos_flag == 0) {print old_line "\tfx:f:" current_utg_pos }
            else {print old_line "\tmv:f:" current_utg_pos }
            }
        else {
            print old_line
            }
        next;
    }
    !/^S/ {print $0; next;}
' $output_dir/unitigs.gfa - > $3


