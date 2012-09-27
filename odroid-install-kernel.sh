#!/bin/sh

LOAD_ADDR=0x4000800
ENTRY_POINT=0x4000800

# Where the U-Boot partition is mounted.
UBOOT_PATH="/media/boot"
set +e
grep "$UBOOT_PATH" /etc/mtab > /dev/null
if [ 0 -ne $? ] ; then
	error "U-Boot partition not mounted."
fi
set -e

getversion

fetchfiles

mkuboot

mkscript

moveconfig

doinitramfs

mkunitrd

copy_to_uboot

echo "Making LITMUS the default ..." >&2
mv $TMP_MOUNT/$SCRIPT_NAME $TMP_MOUNT/boot.scr
echo "done." >&2

rm_tmp_files

echo "All done!" >&2
