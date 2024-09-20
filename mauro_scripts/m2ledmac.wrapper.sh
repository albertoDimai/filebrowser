#!/bin/bash
outfile=${1}.m2ledmac.OUT.log
(
m2ledmac ${i}
) 2>&1 > $outfile
