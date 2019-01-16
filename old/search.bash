#!/usr/bin/env bash

EXE_DIR=$( readlink -e "$0" ) ; EXE_DIR=$( dirname "$EXE_DIR" )
INDEX_DIR="$EXE_DIR/index"

function do_help {
    cat << EOF

This script helps you find out if you've already downloaded a movie or episode of a TV show.
It takes a maximum of 1 argument, and ignores everything else on the command line.
Pass -h, --help, or an empty string to get this help message.
Pass -i to enter interactive mode.
Pass any other string to search for that string.

EOF
}

function do_search {
    echo -e "\033[0;34m===> $1 <===\033[0m"
    grep --color --no-filename --ignore-case "$1" "$INDEX_DIR"/*.index
    echo -e "\033[0;34m====================\033[0m"
}

function do_interactive {
    while true ; do
	echo -e "\033[0;35mEnter a standard POSIX regular expression (don't use quotes) or -q to quit."
	read ARG
	case "$ARG" in
	    -q) echo -e "Goodbye\033[0m" ; exit ;;
	    "") echo -e "... Searching for an empty string seems pretty dumb, don't you think?\n" ;;
	    *) do_search "$ARG" ;;
	esac
    done
}

case "$1" in
    ""|-h|--help) do_help ;;
    -i) do_interactive "$1" ;;
    *) do_search "$1" ;;
esac
