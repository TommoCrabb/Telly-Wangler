#!/usr/bin/env bash

hash find md5sum realpath 0-timestamp || exit

arg_list=( "${@}" )
(( ${#@} == 0 )) && arg_list=( $( pwd ) )

for arg in "${arg_list[@]}" ; do

	echo -e "\n==========\n${arg}\n=========="

	if ! [[ -d "${arg}" ]] ; then
		echo "ERROR: NOT A DIRECTORY - ${arg}"
		continue
	fi

	arg_realpath=$( realpath -e "${arg}" )
	
	mapfile -t file_list < <( find "${arg_realpath}" -maxdepth 1 -type f | sort )

	timestamp=$( 0-timestamp )
	done_file="0-md5-dir_${timestamp}_done"
	fail_file="0-md5-dir_${timestamp}_fail"

	for file in "${file_list[@]}" ; do
		md5sum "${file}" 1> >( tee -a "${done_file}" ) 2> >( tee -a "${fail_file}" )
	done
		
done
