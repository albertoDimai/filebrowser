#!/bin/bash
outfile=${1}.m2hv.OUT.log

(m2hv ${1} ) > $outfile 2>&1 

exit 0;
