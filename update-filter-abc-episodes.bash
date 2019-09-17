#!/usr/bin/env bash

this_file=$( readlink -e "${0}" )
this_dir=$( dirname "${this_file}" )
timestamp=$( date +%F_%T )
titleFilter_file="${this_dir}/filters/abc-titles"
episodeFilter_file="${this_dir}/filters/abc-episodes"
episodeFilterBackup_file="${episodeFilter_file}_${timestamp}"
additions_file_array=( "${@}" )

# Check that all files in ${additions_file_array[@]} exist
for file in "${additions_file_array[@]}" ; do
    [[ -f "${file}" ]] || { echo "ERROR: Couldn't find file '${file}'. Exiting." ; exit ; }
done
# Back up filter file
mv -vn "${episodeFilter_file}" "${episodeFilterBackup_file}" || { echo "ERROR: Couldn't back up ${episodeFilter_file}. Exiting." ; exit ; }
# Process ${additions_file}
sort --unique "${additions_file_array[@]}" "${episodeFilterBackup_file}" | grep -vEf "${titleFilter_file}" > "${episodeFilter_file}"
# Print new lines added to filter file
echo "Lines added to ${episodeFilter_file}:"
grep -vFf "${episodeFilterBackup_file}" "${episodeFilter_file}"
echo "====="
echo "Lines removed from ${episodeFilter_file}:"
grep -vFf "${episodeFilter_file}" "${episodeFilterBackup_file}"
