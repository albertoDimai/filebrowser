#!/bin/bash

##paths are assumed ABSOLUTE

#DRYRUN="echo"


infile="${1}"
infile_name=$(basename "$infile")
outfile=m2hv.OUT.log
outdir="${2}"

COMMANDLINE="${3}"

generated_index=$(basename "$infile_name" .tex)-ind.htm

echo infile $infile
echo infile_name $infile_name
echo outfile $outfile
echo outdir $outdir


mkdir "$outdir"
echo pwd: $(pwd)

(
    cd "$outdir"
    #m2hv e' cattivo e usa il path del fiel per costruire la ri di output
    #quindi noi ce lo copiamo
    cp "$infile" "$infile_name"
    
    echo "EXECUTING: " m2hv "$COMMANDLINE" "./$infile_name"
    echo "----"
    
    ${DRYRUN} m2hv "$COMMANDLINE" "./$infile_name"

    rm -f "$infile_name"

    ln -s "$generated_index" index.html
    
) > "$outdir/$outfile" 2>&1

echo "end"
