#!/bin/bash

outfile="${1}.pdflatex.OUT.log"
outdir=$(dirname "${1}")

(pdflatex -output-directory="${outdir}" "${1}") > "$outfile" 2>&1 

exit 0;
