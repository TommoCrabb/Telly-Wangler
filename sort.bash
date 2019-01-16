#!/usr/bin/env bash

### DEPENDENCIES ###

hash vlc || vlc_status="false" ## VLC is required for playback. If VLC can't be found $vlc_status will be set to 'false'.

### COLOURED TEXT ###
Cn='\033[0m'    ## No colour
Cg='\033[0;32m' ## Green
Cm='\033[0;35m' ## Magenta
Cy='\033[0;33m' ## Yellow

### GLOBAL VARIABLES ###

root_dir="" ## String. Path to the root directory under which all files and folders are located.
title="" ## String. The first part of a file's name. File's with the same title are treated as a set.
delim="||" ## String. Field delimiter used in file names. Shouldn't change.
title_d="" ## String=${title}${delim}. Used to avoid title clashes amongst file sets.
dir="" ## String. Path to the sub-directory that a specific set of files will be moved to.

### FUNCTIONS ###

function msg ## Formats a string and prints it to stdout.
{
	0-print-messages "${1}" && return
	
	local str=$( echo "${1}" | perl -pe '
		  s/(^|\s)\*(\S)/${1}\\033[0;33m${2}/g;	  # Start yellow text on asterisk at beginning of word
		   s/^!/\\033[0;35m/ and s/(\S)\*(\s|$)/${1}\\033[0;35m${2}/g or   # Make text megenta if it starts with "!"
		   s/^/\\033[0;34m/ and s/(\S)\*(\s|$)/${1}\\033[0;34m${2}/g  ; 	# Or green if it does not.
		  # s/^((\\033\[0;..m).*?\S)\*(\s)/${1}${2}${3}/g;			  # Close star quotes
		  s/$/\\033[0m/;		 # Remove formatting at end of string
	' )
	echo -e "${str}"
}

function set_dir ## Takes no arguments. Finds all directories below $root_dir whose name exactly matches $title. Asks the user to pick from this list or make a new directory. Sets the global variable $dir.
{
	local dirs tmp

	while true ; do
		# Create an array of directories (beneath $root_dir) named $title
		mapfile -t dirs < <( find "${root_dir}" -type d -name "${title}" )
		case "${#dirs[@]}" in # Check the number of directories found
			0)  # No directories found. Ask to make a new one.
				msg "@\n${title}:\n"
				ls "${title_d}"*
				msg "\nNO DIRECTORIES FOUND FOR THIS TITLE. WOULD YOU LIKE TO MAKE ONE?\n"
				;;
			1)  # 1 directory found. Assume it's the right one.
				dir="${dirs[0]}"
				return
				;;
			*)	# Ask to use an existing directory or make a new one.
				msg "@\n${title}:\n"
				ls "${title_d}"*
				msg "\nWHERE WOULD YOU LIKE TO MOVE THESE FILES?\n"
				;;
		esac
		select tmp in "${dirs[@]}" "Make a new directory" "Play videos" "Skip title" "Search again" ; do
			case "${tmp}" in
				"Search again") break ;;
				"Skip title") return 1 ;;
				"Make a new directory")	make_dir && return 0 || break ;;
				"Play videos") play_files "${dirs[@]}" ; break ;;
				*) dir="${tmp}" && return 0 ;;
			esac
		done
	done
}

function make_dir ## Takes no arguments. Creates a directory under $root_dir and sets it as $dir.
{
	local wd opt tmp
	wd=$( pwd )
	while true ; do
		msg "\nSELECT LOCATION TO CREATE NEW DIRECTORY *'${title}'* \n"
		select opt in "Select" "Confirm (set as '${tmp}')" "Cancel (leave as '${dir}')" ; do
			case "${opt}" in
				"Cancel (leave as '${dir}')")
					return 1
					;;
				"Select")
					cd "${root_dir}" || { msg "!COULDN'T *cd* INTO *'${root_dir}'*. EXITING." ; exit ; }
					echo ; ls -p ; echo
					read -e -p "ENTER PATH: " tmp
					history -s "${tmp}"
					tmp=$( realpath -e "${tmp}" )/"${title}"
					cd "${wd}"  || { msg "!COULDN'T *cd* INTO *'${wd}'*. EXITING." ; exit ; }
					break 
					;;
				"Confirm (set as '${tmp}')")
					check_dir_path "${tmp}" || break
					mkdir "${tmp}" && dir="${tmp}" && return 0 || break
					;;
			esac
		done
	done
}

function check_dir ## Takes no arguments. Checks $dir to make sure it's a valid directory located under $root_dir
{
	if ! [[ -d "${dir}" && -r "${dir}" && -w "${dir}" ]] ; then
		msg "!SOMETHING WENT WRONG, BECAUSE *'${dir}'* IS NOT A DIRECTORY OR DOESN'T HAVE CORRECT PERMISSIONS. EXITING."
		exit
	fi
	check_dir_path "${dir}" || { msg "!ERROR 555" ; exit ; }
}

function check_dir_path ##
{
	[[ "${1}" == "${root_dir}"/* ]] && return 0 || return 1
}

function move_files ## Takes no arguments. Checks that the user really wants to move all files matching $title_d* to $dir and then moves them.
{
	local opt all_files file

	while true ; do
		check_dir
		echo
		# Show combined view of files we are moving and files already in $dir.
		mapfile -t all_files < <( ls -d "${title_d}"* "${dir}"/* | perl -pe 's|^.*/([^/]+)$|#   $1| or s|^|@>> |' | sort )
		for file in "${all_files[@]}" ; do
			#[[ "${file}" == ">> "* ]] && file="${Cg}${file}${Cn}" # Colour files we are moving green
			#echo -e "${file}"
			msg "${file}"
		done
		msg "\nMOVE TO: *${dir}*\n"
		select opt in "Move" "Re-read filenames" "Select different directory" "Make new directory" "Play videos" "Skip title" ; do
			case "${opt}" in
				"Move") echo "mv -vn" "${title_d}"* "${dir}/" && return || break ;;
				"Re-read filenames") break ;;
				"Select different directory") set_dir || return ; break ;; # Skip title if set_dir returns 1
				"Make new directory") make_dir ; break ;;
				"Play videos") play_files "${dir}" ; break ;;
				"Skip title") return ;;
			esac
		done
	done
}

function set_root_dir ## Takes no arguments. Asks the user to set the $root_dir variable, which is the location of a directory under which all file sets will be moved.
{
	while true ; do
		msg "TYPE THE LOCATION OF THE ROOT DIRECTORY UNDER WHICH YOUR FILES ARE STORED"
		read -e root_dir
		root_dir=$( realpath -e "${root_dir}" ) || continue
		while [[ "${root_dir}" == */ ]] ; do
			root_dir="${root_dir%/}" # Strip trailing slashes
		done
		[[ -d "${root_dir}" ]] && break
		msg "!\nCOULDN'T FIND: *${root_dir}*"
	done
}

function play_files ## Checks if VLC is installed. Accepts any number of directories as arguments and offers to play them or any files in current directory starting with $title_d. 
{
	local list
	
	if [[ "${vlc_status}" == "false" ]] ; then
		msg "!\nCANNOT PLAY FILES. VLC COULD NOT BE FOUND.\n"
	else
		while true ; do
			msg "\nPLAY VIDEOS?\n"
			select list in "./${title}*" "${@}" "Done" ; do
				case "${list}" in
					"Done") return ;;
					"./${title}*") vlc "${title_d}"* ; break ;;
					*) vlc "${list}" ; break ;;
				esac
			done
		done
	fi
}

function list_files ## Lists all files in the current directory whose names start with $title_d.
{
	ls "${title_d}"*
}

function print_help ## Prints any line in this script that contains a double hash (##). Formatting is applied.
{
	0-print-comments "${0}" || perl -ne 's/^\s*(.*##.*)$/${1}\n/ and print' "${0}"
}

### SCRIPT BODY ###

msg "!\nHELLO\n"

set_root_dir

## This script accepts a list of file names as arguments. Files not in the current directory are ignored. If the script is run without arguments, all files in the current directory (*) are selected. If the first argument is "--help", the script immediately runs the function "print_help" and then exits.

# Process arguments
case "${1}" in
	"--help") print_help ; exit ;;
	"") args=( * ) ;;
	*) for arg in "${@}" ; do             # Sanity-checks required for user-supplied arguments  
		   arg=$( basename "${arg}" )     # Limit to files in current directory
		   [[ -f "${arg}" ]] || continue  # Check that arguments are actually file names
		   args+=( "${arg}" )
	   done ;;
esac

# Make an array of unique series titles
mapfile -t titles < <(
	for arg in "${args[@]}" ; do
		echo "${arg}"
	done |
		perl -ne 's/^(.+?)\|\|(.*\|\|)?e\d.*\.mkv$/$1/ and print' | ## Filters out anything that isn't an episode in a series.
		sort | uniq
)

# Loop through series titles
for title in "${titles[@]}" ; do
	title_d="${title}${delim}"
	set_dir || continue # If set_dir returns '1' skip title
	move_files
done

exit

