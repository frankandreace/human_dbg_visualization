awk '
BEGIN {
    FS="\t"
    OFS="\t"
    ORS="\n"
    current_utg_id = -1
    }
    /^S/ {
        old_line=$0
        curr_segment=$2
        print "curr_segment:", curr_segment > /dev/stderr
        while ( curr_segment > current_utg_id) {
            print "INSIDE WHILE" > /dev/stderr
            if (getline < ARGV[2] > 0) {
                current_utg_id = $1
                current_utg_pos = $2
            }
            else { break }
        }
        print "curr_utg_pos:", current_utg_id > /dev/stderr
        if ( curr_segment == current_utg_id ) print old_line "\tfx:f:" current_utg_pos
        else {
            print old_line
            print "INSIDE ELSE" > /dev/stderr
            }
        next;
    }
    !/^S/ {print $0; next;}
' $1 $2 > $3