#!/bin/bash
outfile=${1}.pdflatex.OUT.log

(pdflatex ${1}) > $outfile 2>&1 

exit 0;
