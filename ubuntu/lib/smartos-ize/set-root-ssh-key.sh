#!/usr/bin/env bash
. /lib/smartos-ize/common.sh

if [ ! -f /root/.ssh/authorized_keys ]; then
    authorized_keys=$(mdata-get root_authorized_keys | sed 's/\(ssh-rsa\ \)/\n\1/g' | sed 's/\(ssh-dss\ \)/\n\1/g' 2>>/dev/console)
    if [[ -n ${authorized_keys} ]]; then
    	log "Saving root ssh key"
        mkdir -p /root/.ssh
        echo -e "${authorized_keys}" > /root/.ssh/authorized_keys
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/authorized_keys
    fi
fi