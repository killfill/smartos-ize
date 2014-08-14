#!/usr/bin/env bash

HOST="$1"

if [ -z "$HOST" ]; then
	echo "Usage: $0 REMOTE_HOST"
	exit 1
fi


rsync -av lib root@${HOST}:/
rsync -av usr root@${HOST}:/
ssh root@${HOST} 'rm -f /root/firstboot_done'
ssh root@${HOST} 'grep smartos /etc/rc.local || echo -e "#!/bin/sh -e\n#execute firstboot.sh only once\nif [ ! -e /root/firstboot_done ]; then\nif [ -e /root/firstboot.sh ]; then\n/root/firstboot.sh\nfi\ntouch /root/firstboot_done\nfi\n\n\n\n#smartos-ized\n/lib/smartos-ize/format-second-disk.sh||true\n/lib/smartos-ize/network.sh||true\n/lib/smartos-ize/set-root-ssh-key.sh||true\n/lib/smartos-ize/run-user-script.sh||true\nexit 0" > /etc/rc.local'

#Power button support
ssh root@${HOST} 'apt-get install acpid; modprobe acpi'
