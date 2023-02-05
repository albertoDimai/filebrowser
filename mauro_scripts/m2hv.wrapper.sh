#!/bin/bash
outfile=${1}.OUT.log
(
m2hv ${1}
) 2>&1 > $outfile

