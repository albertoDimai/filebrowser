#!/bin/bash
outfile=m2hv.OUT.log
outdir=${2}

echo outfile $outfile
echo outdir $outdir

mkdir $outdir
cd $outdir

echo "xxx"
echo $(pwd)
(
    echo $(pwd)
    echo "m2hv ${1}"
) 2>&1 > $outdir/$outfile

echo "end"
