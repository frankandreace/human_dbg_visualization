
#!/bin/bash

# Script Name: unitig_dbg_generator
# Author: Francesco Andreace
# Date: 9th of April 2024
# Description: bash script to create a position aware unitig dbg in gfa format of a specific (repeat-masked) region of the genome or chromosome from a set of samples.
# Input: 
#   - the desired chromosome or part of the genome, repeat masked
#   - a fof of the set of samples to consider
# Tools dependencies:
#   - minimap2 to select reads
#   - ggcat to build the dbg
# DISCLAIMER: THE SCRIPT CONSIDERS THESE 2 TOOLS ALREADY INSTALLED IN YOUR SISTER / CLUSTER


SCRIPT_NAME="position_dbg_generator" #$(basename $0)

#SETTING DEFAULT PARAMETERS
DEFAULT_KSIZE=31
DEFAULT_THREADS=8
DEFAULT_MIN_COUNT=2
DEFAULT_OUTDIR=output

USAGE=$'\nUsage: '"${SCRIPT_NAME}"' [-k KMER-SIZE] [-t NUM-THREADS] [-c MIN-COUNT] [-o OUT-DIR] <input_region.fa> <input_seqfile.seq>

Arguments:
     -h              print this help and exit
     -k              kmer size for ggcat and kmtricks (default:31)
     -t              number of cores (default:4)
     -c              minimum count of kmers to be retained (default:1)
     -o              output directory (default:output)


Positional arguments:
     <input_file>         input region (fasta)
     <input_file>         input seqfile (fof)
'


#PARSING INPUT OPTIONS
k_len=$DEFAULT_KSIZE
thr=$DEFAULT_THREADS
min_count=$DEFAULT_MIN_COUNT
output_dir=$DEFAULT_OUTDIR

while getopts ":hktco" flag; do
   case "${flag}" in
      h) $(>&2 echo "${USAGE}")
         exit 0
         ;;
      k) k_len=${OPTARG}
         ;;
      t) thr=${OPTARG}
         ;;
      c) maxlen=${OPTARG}
         ;;
      o) output_dir=${tOPTARG}
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
input_file=${@:$OPTIND+1:1}

# MAP READS FOF WITH MINIMAP2 TO SELECTED REGION / CHROMOSOME / MASKED GENOME AND TAKE OUT ONLY READS MAPPING TO SELECTED FILE 
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
