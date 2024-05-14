#!/bin/bash
infile=$1
outfile=$2
ksize=$3

awk -v "kmer_size=$ksize" '

BEGIN { 
name = ""
print "H\tVN:Z:1.0\tks:i:" kmer_size
print "Opening GFA" > "/dev/stderr"
overlap = kmer_size-1
OFS="\t"
}
!/^>/ { printf $0 ; next }
{
    #printing the end of the segment and links
    #printf tags[1]
    #print tags_p > "/dev/stderr"
    for (j = 1; j < tags_p; j++) 
        printf tags[j]
    for (i = 1; i < links_p; i++){
        gsub(":","\t",links[i])
        sub("L\t","",links[i])
        print "L", utg_name, links[i], overlap "M" 
    }
    links_p = 1
    tags_p = 1

    utg_name = substr($1,2)
    printf "S" "\t" utg_name "\t"
    for (i = 2; i <= NF ; i++){
        #print match($i,":") > "/dev/stderr"
        if ( match($i,":") == 2 ) {
            links[links_p++] = $i
            }
        else {
            tags[tags_p++] = "\t"
            tags[tags_p++] = $i
        }
    }
    tags[tags_p++] = "\n"
    #print length(tags) > "/dev/stderr"
}

END {
    print "Done." > "/dev/stderr"
}

' $infile > $outfile

