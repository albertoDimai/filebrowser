#!/bin/bash
outfile=${1}.pdflatex.OUT.log
(
    pdflatex ${i}
) 2>&1 > $outfile

