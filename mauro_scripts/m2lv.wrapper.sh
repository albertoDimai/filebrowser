#!/bin/bash

##paths are assumed ABSOLUTE

#DRYRUN="echo"


infile="${1}"
infile_name=$(basename "$infile")
outfile=m2lv.OUT.log
outdir="${2}"

COMMANDLINE="${3}"
(
echo infile $infile
echo infile_name $infile_name
echo outfile $outfile
echo outdir $outdir
) > /tmp/llo

mkdir -p "$outdir"
echo pwd: $(pwd)

(
    cd "$outdir"
    #m2lv e' cattivo e usa il path del fiel per costruire la ri di output
    #quindi noi ce lo copiamo
    cp "$infile" "$infile_name"
    
    echo "EXECUTING: " m2lv "$COMMANDLINE" "./$infile_name"
    echo "----"
    
    ${DRYRUN} m2lv $COMMANDLINE "./$infile_name"

    rm -f "$infile_name"

) > "$outdir/$outfile" 2>&1

echo "end"
