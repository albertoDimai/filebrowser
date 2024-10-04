#!/bin/bash

infile="${1}"
infile_name=$(basename "$infile")
outfile="${infile_name}.OUT.log"

(
    pdflatex "${infile}"
) 2>&1 > $outfile
