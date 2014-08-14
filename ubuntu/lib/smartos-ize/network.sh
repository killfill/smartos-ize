#!/usr/bin/env bash
. /lib/smartos-ize/common.sh

#Network Interface

file='/etc/network/interfaces'
echo "#Customized by smartos-ize" > $file

echo "auto lo" > $file
echo "iface lo inet loopback" >> $file

interfaces=$(ifconfig -a | grep ^eth | awk '{print $1}')
for i in ${interfaces[@]} ; do
	log "Configuring $i wth dhcp"
	echo "auto $i" >> $file
	echo "iface $i inet dhcp" >> $file
	ifup $i
done


#Hostname
name=$(mdata-get hostname)
if [ $? -eq 0 ]; then
	log "Setting hostname to $name"
	hostname $name
	echo $name >> /etc/hostname
	echo "127.0.0.1 localhost $name" > /etc/hosts
fi

#SSH KEY?...
# which dpkg-reconfigure >/dev/null 2>&1 || lib_smartdc_info "ERROR: dpkg-reconfigure not found"
# keycount=$(find /etc/ssh -name 'ssh_host_*_key*' | wc -l)
# if [[ $keycount -eq 0 ]] ; then
#   dpkg-reconfigure openssh-server
# fi