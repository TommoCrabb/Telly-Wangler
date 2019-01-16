#!/usr/bin/env bash

this_file=$( readlink -e "${0}" )
this_dir=$( dirname "${this_file}" )
timestamp=$( date +%F_%T )
titleFilter_file="${this_dir}/filters/abc-titles"
titleFilterBackup_file="${titleFilter_file}_${timestamp}"
additions_file_array=( "${@}" )

# Check that all files in ${additions_file_array[@]} exist
for file in "${additions_file_array[@]}" ; do
    [[ -f "${file}" ]] || { echo "ERROR: Couldn't find file '${file}'. Exiting." ; exit ; }
done
# Back up filter file
mv -vn "${titleFilter_file}" "${titleFilterBackup_file}" || { echo "ERROR: Couldn't back up ${titleFilter_file}. Exiting." ; exit ; }
# Process ${additions_file}
perl -ne 's/^.*(http.*)[0-9]{3}S00.*$/${1}[0-9]{3}S00/ and print' "${additions_file_array[@]}" | sort --unique --output="${titleFilter_file}" "${titleFilterBackup_file}" - 
# Print new lines added to filter file
echo "Lines added to ${titleFilter_file}:"
grep -vFf "${titleFilterBackup_file}" "${titleFilter_file}"
