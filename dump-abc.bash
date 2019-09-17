#!/usr/bin/env bash
# set -x

hash jq readlink dirname basename date mkdir wget sed grep sort cp || exit

# Define locations of files that need to exist
this_file=$( readlink -e "${0}" )
this_dir=$( dirname "${this_file}" )
jqConf_file="${this_dir}/jq-abc.conf"
episodeFilter_file="${this_dir}/filters/abc-episodes"
titleFilter_file="${this_dir}/filters/abc-titles"
# Check that they actually do exist
for file in "${jqConf_file}" "${titleFilter_file}" "${episodeFilter_file}" ; do
    [[ -f "${file}" ]] || { echo "ERROR: Couldn't find ${file}. Exiting" ; exit ; }
done
# hash jq || { echo "ERROR: Couldn't find 'jq'. Exiting." ; exit ; }
# Define names of files that will be created
cmd=$( basename "${0}" )
timestamp=$( 0-timestamp ) || timestamp=$( date +%Y-%m%d-%H%M%S )
dump_file="${cmd}_${timestamp}_0-dumped"
formatted_file="${cmd}_${timestamp}_1-formatted"
filtered_file="${cmd}_${timestamp}_2-filtered"
pruned_file="${cmd}_${timestamp}_3-pruned"

# Create working directory
mkdir "${timestamp}_abc" || { echo "ERROR: Couldn't create working directory. Exiting." ; exit ; }
cd "${timestamp}_abc"
# Get dump
wget http://iview.abc.net.au/api/programs -O "${dump_file}" || { echo "ERROR: Wget failed to take dump. Exiting." ; exit 1 ; }
# Format dump
jq -f "${jqConf_file}" < "${dump_file}" | sed -r 's/^"(.*)"$/\1/' | sort > "${formatted_file}"
# Filter dump
grep -vEf "${titleFilter_file}" "${formatted_file}" | grep -vFf "${episodeFilter_file}" > "${filtered_file}"
# Make copy of dump for manual editing
cp -vn "${filtered_file}" "${pruned_file}"
