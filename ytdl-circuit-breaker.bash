#!/usr/bin/env bash

du1=$( du -s . )

while true ; do
	sleep 5m 
	du2=$( du -s . )
	if [[ "${du1}" = "${du2}" ]] ; then
		killall --verbose youtube-dl || exit
	fi
	du1="${du2}"
done
