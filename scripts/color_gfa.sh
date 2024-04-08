awk '
BEGIN {
    FS="\t"
    OFS="\t"
    ORS="\n"
    }
    /^S/ {
        old_line=$0
        curr_utg_id=$2
        while ( curr_utg_id > current_utg_pos) {
            if (getline < ARGV[2] > 0) {
                current_utg_pos = $1
            }
            else { break }
        }
        if ( curr_utg_id == curr_utg_pos ) print old_line "fx:f:"position++
        else print old_line
    }
    !/^S/ {print $0; next;}
'