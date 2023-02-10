#!/bin/bash
outfile="${1}.m2ledmac.OUT.log"

(m2ledmac "${1}") > "$outfile" 2>&1

exit 0;
