#!/bin/bash


#map unitigs to reference and detect position in the chromosome

minimap2 -xsr --secondary=no $1 $2 | awk '
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
    ' |sort -k1,1n > $3
