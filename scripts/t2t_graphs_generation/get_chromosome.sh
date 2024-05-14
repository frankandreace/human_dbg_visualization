#!/bin/bash

input_fasta=$1
outfile=$2
chromosome=$3

# TAKE SELECTED CHROMOSOME

echo "EXTRACTING $chromosome"
awk -v "chromosome=$chromosome" '
BEGIN {print "looking for " chromosome > "/dev/stderr"}
/^>/ {
    chr_id=$1
    sub(">","",chr_id)
    if (chr_id == chromosome){
        print_line=1
        print $0
    }
    else {if (print_line==1) exit}
    next;
}
!/^>/ {
    if (print_line==1) print $0
    next;
}
' < $input_fasta > $outfile
