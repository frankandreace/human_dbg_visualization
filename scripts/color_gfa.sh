awk '
BEGIN {
    FS="\t"
    OFS="\t"
    ORS="\n"
    current_utg_id = -1
    stderr="/dev/stderr"
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
' $1 $2 > $3