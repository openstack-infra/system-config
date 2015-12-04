#!/bin/bash

# This script generates an index file for every directory in the wheel mirror
# hierarchy.

DATA_DIRECTORY=$1

function build_index {
  index="<!DOCTYPE html>"
  index="$index<html><body><ul>"

  # Match all strings that are /A/A(B/AB[C..])?$ Terminating at the end
  # permits us to only grab directory listings rather also matching multiple
  # times on files inside directories.
  regex="\/([^/])\/\1(([^/])\/\1\3[^/]+)?$"
  for f in $(find $1/*)
  do
    # Pull only the AFS-Matching directories
    if [[ $f =~ $regex ]]; then
      # Get the last name in the folder path, the package name.
      dir=$(basename $BASH_REMATCH)
      # Echo it out.
      index="$index<li><a href=\"$dir/\">$dir</a></li>"
    fi
  done

  index="$index</ul></body></html>"
  echo $index > $2
}

for dir in $DATA_DIRECTORY/*
do
  build_index $dir "$dir/index.html"
done