filename=$1
outfile=$2
out_filename="${filename%.*}.gz"
unzstd $1 | gzip > $out_filename
echo $out_filename >> $outfile