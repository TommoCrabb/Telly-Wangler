#!/usr/bin/env bash
# set -x

# Use these as tags to format text from the "echo -e" command (eg: echo -e "This is some ${RED}red${REG} text.")
RED='\033[0;31m' # Red
BLU='\033[0;34m' # Blue
PUR='\033[0;35m' # Purple
REG='\033[0m'    # Regular (use this as a closing tag)

this_file=$( readlink -e "${0}" )
this_dir=$( dirname "${this_file}" )

timestamp=$( date +%Y-%m-%d_%H%M%S )
error_file="${timestamp}_error"
log_file="${timestamp}_log"
fail_file="${timestamp}_fail"
done_file="${timestamp}_done"

function throw_error
# Takes a string as argument and writes it to both ${error_file} and stdout (in red text).
# If a 2nd argument of '1' is supplied, print exit message & exit.
{
	echo -e "${RED}ERROR: ${1}${REG}"
	echo -e "${1}" >> "${error_file}"
	[[ "${2}" == 1 ]] && { echo "${RED}EXITING...${REG}" ; exit ; }
}

function log_this
# Takes a string as argument and writes it to both ${log_file} and stdout (in blue text).
{
	echo -e "${BLU}${1}${REG}"
	echo -e "${1}" >> "${log_file}"
}

function failed_download
# Takes a string as argument and writes it to both ${fail_file} and stdout (in red text).
{
	echo -e "${RED}FAILED DOWNLOAD: ${1}${REG}"
	echo -e "${1}" >> "${fail_file}"
}

function finished_download
{
	echo -e "${BLU}FINISHED DOWNLOAD: ${1}${REG}"
	echo -e "${1}" >> "${done_file}"
}

# function change_dir
# # Takes the location of a directory as argument and tries to cd into it. Exits on failure.
# {
#     if [[ "${PWD}" != "${1}" ]] ; then
# 	cd "${1}" || { throw_error "COULDN'T 'cd' INTO '${1}'. EXITING." ;  ; }
#     fi
# }

function check_file
# Takes 2 strings. With the 1st, each character represents a tests to be performed on a file or directory.
# 2nd string is the file or directory to be tested. If any test fails, immediately returns a value of '1'.
{
    local t="${1}"
    local f="${2}"
    local i
    for (( i=0 ; $i < ${#t} ; i++ )) ; do
	case "${t:$i:1}" in
	    r) [[ -r "$f" ]] || { throw_error "CAN'T READ '${f}'."            ; return 1 ; } ;;
	    w) [[ -w "$f" ]] || { throw_error "CAN'T WRITE TO '${f}'."        ; return 1 ; } ;;
	    x) [[ -x "$f" ]] || { throw_error "CAN'T EXECUTE '${f}'."         ; return 1 ; } ;;
	    f) [[ -f "$f" ]] || { throw_error "CAN'T FIND FILE '${f}'."       ; return 1 ; } ;;
	    d) [[ -d "$f" ]] || { throw_error "CAN'T FIND DIRECTORY '${f}'."  ; return 1 ; } ;;
	    *) throw_error "FUNCTION 'check_file' FAILED TO MATCH '${t:$i:1}'."    ; return 1 ;;
	esac
    done
}

function set_config_file
# Takes 1 string as argument and uses it to set the location of the ${config_file} that youtube-dl should use.
{
    config_file="${this_dir}/youtube-dl-${1}.conf"
    check_file fr "${config_file}" || throw_error "Couldn't find config file ${config_file}." 1
}

function download_file
{
    youtube-dl --config-location "${config_file}" "${1}" && finished_download "${1}" || failed_download "${1}"
}

function get_simple
{
	set_config_file "${1}"
	download_file "${2}"
}

 
function check_source
{
	case "${1}" in
	\#*) log_this "SKIPPING COMMENTED LINE: ${1}" ;;
	daily) get_daily ;;
	*iview.abc.net.au/*) get_simple "abc" "${1}" ;;
	*sbs.com.au/ondemand/video/*) get_simple "sbs" "${1}" ;;
	nine) get_9 "${1}" ;;
	seven) get_7 "${1}" ;;
	ten) get_10 "${1}" ;;
	*twitch.tv*) get_twitch "${1}" ;;
	*youtube.com*) get_youtube "${1}" ;;
	*) throw_error "FAILED TO RECOGNISE INPUT '${1}'" ;;
	esac
}

for arg in "${@}" ; do
	if check_file fr "${arg}" ; then
	while read line ; do check_source "${line}" ; done < "${arg}"
	else
	check_source "${arg}"
	fi
done
