#!/usr/bin/env bash
. /lib/smartos-ize/common.sh

SFDISK=`which sfdisk 2> /dev/null`
MKE2FS=`which mke2fs 2> /dev/null`
TUNE2FS=`which tune2fs 2> /dev/null`
MOUNT_BIN=`which mount 2> /dev/null`

checkformount() {
   fstest=$(df -h | grep '/dev/vdb1')
   if [ -n "$fstest" ] ; then
     fssize=$(echo $fstest | sed 's/[[:space:]]\{2,\}/ /g' | cut -d ' ' -f2)
     log "$fssize data disk is mounted on /dev/vdb1"
     return 1
   else
     log "no data disk is mounted on /dev/vdb1"
     return 0
   fi
}

# Start of Main

log "Start of script"

if [[ ! -e /dev/vdb ]] ; then
  fatal "secondary disk '/dev/vdb' not found. exiting."
fi

if [[ -z $SFDISK ]] ; then
  fatal "sfdisk binary not found. exiting."
fi

## Sanity check
checkformount
return_val=$?
if [ "$return_val" -eq 1 ]; then
  fatal "data disk is already mounted"
else
  log "no data disk is mounted"
fi

partexists=$($SFDISK -l /dev/vdb 2>/dev/null | grep vdb1 | awk '{print $8}')
if [ "$partexists" != "" ] ; then
   if [[ -n "$DEBUG" ]]; then
      log "partition table already exists. skipping."
   else
      fatal "partition table already exists. skipping."
      exit 0;
   fi
fi

# Otherwise we're creating the partition, formatting it, and mounting it
log "creating partition /dev/vdb1"
echo "0,,L,*" | $SFDISK /dev/vdb 2>/dev/null >/dev/null

# need this sleep to let partition table to update
# if not then /dev/vdb1 will not exist
log "sleeping for update of partition table for /dev/vdb1"
sleep 2

log "creating ext4 filesystem on /dev/vdb1"
if [[ -e /dev/vdb1 ]] ; then
   $MKE2FS -vj -t ext4 /dev/vdb1 2>/dev/null >/dev/null
   log "created ext4 filesystem on /dev/vdb1"
else
   fatal "did not create ext4 filesystem on /dev/vdb1"
fi

# Check for /data and make it
if [[ ! -e /data ]]; then
    log "making /data dir mount point"
    mkdir /data
fi

# add entry to fstab so data disk is mounted on reboot
fsentry=$(grep '/dev/vdb1' /etc/fstab)
if [[ -z $fsentry ]] ; then
  log "adding fstab entry for /dev/vdb1"
  printf "/dev/vdb1\t\t/data\t\t\text4\tdefaults\t0 0\n" >> /etc/fstab
fi

# mount the data disk
log "mounting /dev/vdb1 as /data"
$MOUNT_BIN /data/

checkformount

return_val=$?
if [ "$return_val" -eq 1 ]; then
  log "data disk is mounted"
else
  fatal "no data disk is mounted"
fi

# reducing reserve space from default of 1%
# on larger disks this takes up more space than needed
# set reserved block percentage based on disk size
fssize=$(df -k | grep '/dev/vdb1' | sed 's/[[:space:]]\{2,\}/ /g' | cut -d ' ' -f2 )

if [ $fssize -le 15728640 ]; then
   RESERVE_BLOCK_PERCENTAGE="0.5"
elif [ $fssize -le 31457280 ]; then
   RESERVE_BLOCK_PERCENTAGE="0.25"
elif [ $fssize -le 104857600 ]; then
   RESERVE_BLOCK_PERCENTAGE="0.1"
elif [ $fssize -le 209715200 ]; then
   RESERVE_BLOCK_PERCENTAGE="0.05"
else
   RESERVE_BLOCK_PERCENTAGE="0.02"
fi

log "setting reserved blocks to ${RESERVE_BLOCK_PERCENTAGE}% on /dev/vdb1"
$TUNE2FS -m $RESERVE_BLOCK_PERCENTAGE /dev/vdb1 2>/dev/null >/dev/null

# reducing time for fsck
log "setting auto fsck to 6 months on /dev/vdb1"
$TUNE2FS -c 0 -i 6m /dev/vdb1 2>/dev/null >/dev/null

log "End of script"

exit 0