#!/usr/bin/env bash

timestamp=$( date +%Y-%m%d-%H%M%S )

if [[ -n "${1}" ]] ; then
	echo "${1}_${timestamp}"
else
	echo "${timestamp}"
fi
