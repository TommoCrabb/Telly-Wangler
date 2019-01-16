#! /usr/bin/env bash

# VARIABLES
ytdl="$HOME/bin/youtube-dl"
ytdl_abc_opts="$( dirname $( readlink -e $0 ) )/opts-abc.conf"
ytdl_sbs_opts="$( dirname $( readlink -e $0 ) )/opts-sbs.conf"
list="$1"
date="$( date --rfc-3339=ns )"
log="tv-download-log_$date"
err="tv-download-err_$date"

# SANITY CHECKS
[[ -x "$ytdl" ]] || { echo "ERROR: $ytdl was not found or is not executable" ; exit ; }
[[ -r "$list" ]] || { echo "ERROR; $list was not found or is not readable" ; exit ; }
[[ -r "$ytdl_abc_opts" ]] || { echo "ERROR: Couldn't find $ytdl_abc_opts" ; exit ; }
[[ -r "$ytdl_sbs_opts" ]] || { echo "ERROR: Couldn't find $ytdl_sbs_opts" ; exit ; }

# BODY
while read url ; do

	[[ "$url" = "#"* ]] && continue
	echo "$( date --rfc-3339=ns ) || $url" | tee -a "$log" "$err"

	if [[ "$url" = "http://iview.abc.net.au"* ]] ; then
	    "$ytdl" --config-location "$ytdl_abc_opts" "$url" 1> >( tee -a "$log" ) 2> >( tee -a "$err" )
	else
	    "$ytdl" --config-location "$ytdl_sbs_opts" "$url" 1> >( tee -a "$log" ) 2> >( tee -a "$err" )
	fi

done < "$list"
