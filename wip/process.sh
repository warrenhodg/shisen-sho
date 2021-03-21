#!/bin/bash
infile=$1
outfile=${infile:6:4}.png
echo "Converting >$infile< to >$outfile<"
convert "$infile" -crop 527x667+47+186 -background none -extent 617x760-47-47 border.png -compose Over -composite $outfile
