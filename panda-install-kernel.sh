#!/bin/sh

set -e

error() {
	echo "$@" >&2
	exit 1
}

TMP_MOUNT=$(mktemp -d)

# The FAT u-boot bootloader partition.
UBOOT_PART=/dev/mmcblk0p1

# This is machine specific, AFAIK.
LOAD_ADDR=0x80008000
ENTRY_POINT=0x80008000

getversion

fetchfiles

mkuboot

mkscript

moveconfig

doinitramfs

mkuinitrd

echo "Mounting u-boot partition ..." >&2
sudo mount $UBOOT_PART $TMP_MOUNT
echo "done." >&2

UBOOT_PATH=$TMP_MOUNT
copy_to_uboot

echo "Unmounting u-boot partition ..." >&2
sudo umount $TMP_MOUNT
echo "done." >&2

rm_tmp_files
rm -rf $TMP_MOUNT

echo "All done!" >&2
