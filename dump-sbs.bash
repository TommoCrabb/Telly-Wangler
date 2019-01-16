#!/usr/bin/env bash
# set -x

########################
# PREPARATIONAL BULLSHIT (Remember, proper planning and preparation prevents piss-poor performance)
########################

hash jq readlink dirname basename date mkdir wget sed grep sort cp || exit

# FUNCTIONS
function warn_invalid_input { echo -e "\n${RED}INVALID INPUT! TRY AGAIN, DICKHEAD!${REG}\n" ; }
function failed_write { echo -e "\n${RED}ERROR: Failed to write '$1'. Exiting.${REG}\n" ; exit $2 ; }

# SETUP
# Use these as tags to format text from the "echo -e" command (eg: echo -e "This is some ${RED}red${REG} text.")
RED='\033[0;31m' # Red
BLU='\033[0;34m' # Blue
REG='\033[0m'    # Regular (use this as a closing tag)
#
# Define locations of files that need to exist
this_file=$( readlink -e "${0}" )
this_dir=$( dirname "${this_file}" )
jqConf_file="${this_dir}/jq-sbs.conf"
titleFilter_file="${this_dir}/filters/sbs-titles"
episodeFilter_file="${this_dir}/filters/sbs-episodes"
# Check that they actually do exist
for file in "${jqConf_file}" "${titleFilter_file}" "${episodeFilter_file}" ; do
    [[ -f "${file}" ]] || { echo "ERROR: Couldn't find ${file}. Exiting" ; exit ; }
done
# hash jq || { echo "ERROR: 'jq' needs to be installed. Exiting." ; exit ; }
# Define names of files that will be created 
cmd=$( basename "${0}" )
timestamp=$( 0-timestamp ) || timestamp=$( date +%F_%T )
dump_baseName="${cmd}_${timestamp}_0-dump"
formatted_file="${cmd}_${timestamp}_1-formatted"
filtered_file="${cmd}_${timestamp}_2-filtered"
pruned_file="${cmd}_${timestamp}_3-pruned"
#

###########################
# ON TO THE ACTUAL SCRIPT #
###########################

# Create working directory
mkdir "${timestamp}_sbs" || { echo "ERROR: Couldn't create working directory. Exiting." ; exit ; }
cd "${timestamp}_sbs"

# Ask user for the number of days worth of shit to get
valid_days_rgx='^[[:digit:]]{1,3}$'
while true ; do
    echo -e "How many days worth of shit do you want to get?\n"
    read -p 'Type a number from 1-365 and press "Enter": ' num_of_days
    [[ "${num_of_days}" =~ ${valid_days_rgx} ]] || { warn_invalid_input ; continue ; }
    (( ${num_of_days} >= 1 && ${num_of_days} <= 365 )) || { warn_invalid_input ; continue ; }
    break
done

# Build URL components
end_time=$( date +%s )
start_time=$( date +%s -d "${num_of_days} days ago" )
wget_url="http://www.sbs.com.au/api/video_feed/f/Bgtm9B/sbs-section-programs?form=json&byPubDate=${start_time}000~${end_time}000&range="
ranges=( "1-500" "501-1000" "1001-1500" "1501-2000" "2001-2500" "2501-3000" "3001-3500" "3501-4000" "4001-4500" "4501-5000" "5001-5500" "5501-6000" "6001-6500" "6501-7000" )

# Request the shit
for range in "${ranges[@]}" ; do
    echo -e "\n${BLU}W-GETTING ${range}${REG}\n"
    wget -O "${dump_baseName}_${range}" "${wget_url}${range}"
done

# Nicely format the shit
jq -f "${jqConf_file}" "${dump_baseName}"_* | sed -r 's/^"(.*)"$/\1/' | sort > "${formatted_file}"
grep -vEf "${titleFilter_file}" "${formatted_file}" | grep -vFf "${episodeFilter_file}" > "${filtered_file}"
cp -vn "${filtered_file}" "${pruned_file}"

