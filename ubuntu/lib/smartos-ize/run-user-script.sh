#!/usr/bin/env bash
. /lib/smartos-ize/common.sh

file="/root/user-script"
mdata-get user-script > $file



if [ $? -eq 0 ] ; then
	chmod +x $file
	log "Runnning user-script"
	exec $file
fi
