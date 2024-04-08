#map unitigs to reference and detect position in the chromosome

minimap2 -xsr --secondary=yes $1 $2 | awk '
    BEGIN { 
    FS="\t" 
    OFS="\t" 
    ORS="\n"
    sum_0=0; sum_60=0; sum_diff=0; count=0 
    }
    { count++
    if ($12 == 0) sum_0++ 
    if ($12 == 60) {sum_60++;  print $1, $9, $12}
    if ($12 != 0 && $12 != 60) sum_diff ++ 
    } 
    END { 
        print "alignment_score. 0:" sum_0/count " ; 60:" sum_60/count " ; !=: " sum_diff/count > "stats.tsv"
        print sum_0+sum_60+sum_diff, count >> "stats.tsv" 
    }
    ' | sort -k2,2n \
    | awk '
    BEGIN {
    FS="\t"
    OFS="\t"
    ORS="\n"
    pos_id=0 
    }
    {print $1, pos_id++ }
    ' | sort -k1,1n > $3

    #    | awk '
    #BEGIN {
    #FS=","
    #FS="\t"
    #}
    #{print $1, $2}
    #' 
