#!/usr/bin/env bash

[[ -d "$1" ]] || { echo "This script requires a valid directory as an argument." ; exit ; }

cd "$1"
find -type f -iregex ".*\.\(mp4\|mkv\|flv\)$" | rev | cut -d '/' -f 1 | rev | sort
