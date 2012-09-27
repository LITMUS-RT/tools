#!/bin/sh

. $(dirname $0)/arm-installer-common.sh

# This is machine specific, AFAIK.
LOAD_ADDR=0x40008000
ENTRY_POINT=0x40008000

# Where the U-Boot partition is mounted.
UBOOT_PATH="/media/boot"
set +e
grep "$UBOOT_PATH" /etc/mtab > /dev/null
if [ 0 -ne $? ] ; then
	error "U-Boot partition not mounted."
fi
set -e

KVERSION=$(getversion)
CONFIG_FILE="config-$KVERSION"

fetchfiles

mkuboot

mkscript

moveconfig

doinitramfs

mkuinitrd

copy_to_uboot

echo "Making LITMUS the default ..." >&2
mv $UBOOT_PATH/$SCRIPT_FILE $UBOOT_PATH/boot.scr
echo "done." >&2

rm_tmp_files

echo "All done!" >&2
