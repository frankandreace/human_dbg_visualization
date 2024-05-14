#!/bin/bash

input_fasta=$1
input_fof=$2
outfile=$3
chromosome=$4

# TAKE SELECTED CHROMOSOME
if [ $chromosome != "a" ]
then
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
else
cp $input_fasta $outfile
fi

# MASK WITH BEDFILES
# https://bedtools.readthedocs.io/en/latest/content/tools/maskfasta.html
#bed_id=0
#cp $outfile $outfile.$bed_id
echo "REMOVING REGIONS" 
while IFS= read -r bedfile; do
    bedtools maskfasta -fi $outfile -bed $bedfile -fo $outfile.temp #.$((bed_id+1))
    mv $outfile.temp $outfile
    #((bed_id++))
done < $input_fof
