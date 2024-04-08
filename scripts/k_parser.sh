#!/bin/awk -f
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