#!/bin/bash

##paths are assumed ABSOLUTE

#DRYRUN="echo"


infile="${1}"
infile_name=$(basename "$infile")
outfile=pdflatex.OUT.log
outdir="${2}"

##ASSUMIAMO (e non funzona altrimenti) che outdir e la path del file siano la medesima !!
## commandline non viene passata dal server quindi di fatto e' sempre vuoto
COMMANDLINE="${3}"

echo infile $infile
echo infile_name $infile_name
echo outfile $outfile
echo outdir $outdir


echo pwd: $(pwd)

(
    cd "$outdir"
    echo "EXECUTING: " pdflatex --interaction=nonstopmode "$COMMANDLINE" "./$infile_name"
    echo "----"

    ${DRYRUN} pdflatex --interaction=nonstopmode $COMMANDLINE "./$infile_name"

) > "$outdir/$outfile" 2>&1

echo "end"
