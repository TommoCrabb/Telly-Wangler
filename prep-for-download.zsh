#!/usr/bin/env zsh
# This script takes a single file of type "0-tv-dump...3-pruned"
# It creates a "0-tv-dump...4-links" file, updates the appropriate episodes filter,
# and creates a "0-tv-dump...5-skipped" file, which can be used to update the title filter.
setopt extended_glob

function fatal {
	echo "FATAL ERROR: $1"
	exit
}

[[ -f $1 && -r $1 ]] || fatal "Requires 1 readable file as input"

# Sort out file names
if [[ $1 == (#b)(0-tv-dump-(*)_[-0-9]##)_3-pruned ]] ; then
	baseName=$match[1]
	channel=$match[2]
	linksFile="${baseName}_4-links" 
else
	date=$( date +%Y-%m%d-%H%M%S )
	linksFile="0-tv-downloads_${date}_4-links"
fi

# Make links file
while read line ; do
	if [[ $line == (#b)*\|\|(http://iview.abc.net.au/programs/*) ]] ; then
		echo $match[1] >>$linksFile
	elif [[ $line == (#b)([^|]##)\|\|([0-9]##)\|\|([0-9]## days)\|\|* ]] ; then
		echo "https://www.sbs.com.au/ondemand/video/$match[2] # $match[3] # $match[1]" >>$linksFile
	fi
done < $1

# Only continue if input file uses standard naming convention
[[ -z $baseName ]] && exit

# Sort sbs by days available
[[ $channel == sbs ]] && sort --numeric-sort --field-separator='#' --key=2 --output=$linksFile $linksFile

# Update episode filter & make a file with skipped videos
if [[ -f ${baseName}_2-filtered ]] ; then
	0-tv-update-filter-$channel-episodes ${baseName}_2-filtered
	grep -vFf $1 ${baseName}_2-filtered > ${baseName}_5-skipped
fi
