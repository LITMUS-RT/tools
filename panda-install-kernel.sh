#!/bin/sh

set -e

error() {
	echo "$@" >&2
	exit 1
}

# The FAT u-boot bootloader partition.
UBOOT_PART=/dev/mmcblk0p1

# Build host for ARM.
HOST="pound.cs.unc.edu"

if [ $# -ne 2 ] ; then
	error "Usage: `basename $0` <REMOTE KDIR> <BOOT-SCRIPT>"
fi

SRC_ROOT=$1
SCRIPT_NAME=$2

set +e
VERSION=$(ssh $HOST cat $SRC_ROOT/include/config/kernel.release)
set -e
if [ "x" = "x$VERSION" ] ; then
	error "Could not determine version"
fi

if [ ! -f "$SCRIPT_NAME" ] ; then
	error "Boot script not a file: $SCRIPT_NAME"
fi

TMP_DIR=$(mktemp -d)
TMP_MOUNT=$(mktemp -d)

ZIMAGE_NAME="zImage-litmus"
UIMAGE_NAME="uImage-litmus"
CONFIG_NAME="config-$VERSION"
INITRD_NAME="uInitrd-litmus"
SCR_NAME="boot-litmus.scr"

echo "Fetching files from $HOST ..." >&2
rsync -P cjk@$HOST:$SRC_ROOT/arch/arm/boot/zImage $TMP_DIR/$ZIMAGE_NAME
rsync -P cjk@$HOST:$SRC_ROOT/.config $TMP_DIR/$CONFIG_NAME
echo "done." >&2

echo "Generating kernel u-boot image..." >&2
mkimage -A arm -O linux -T kernel -C none -a 0x80008000 \
	-e 0x80008000 -d $TMP_DIR/$ZIMAGE_NAME $TMP_DIR/$UIMAGE_NAME >&2
echo "done." >&2

echo "Generating u-boot configuration ... " >&2
mkimage -A arm -T script -C none -d "$SCRIPT_NAME" $TMP_DIR/$SCR_NAME >&2
echo "done." >&2

echo "Moving vmlinuz and config fils to /boot ..." >&2
sudo cp $TMP_DIR/$ZIMAGE_NAME /boot/vmlinuz-$VERSION
sudo cp $TMP_DIR/$CONFIG_NAME /boot/
echo "done." >&2

echo "Creating initramfs (ignore module errors) ... " >&2
sudo update-initramfs -k $VERSION -c
echo "done." >&2

echo "Making u-boot initrd image ... " >&2
mkimage -A arm -O linux -T ramdisk -C none -a 0x0 -e 0x0 \
	-d /boot/initrd.img-$VERSION $TMP_DIR/$INITRD_NAME >&2
echo "done." >&2

echo "Mounting u-boot partition ..." >&2
sudo mount $UBOOT_PART $TMP_MOUNT
echo "done." >&2

echo "Copying files to u-boot partition ..." >&2
sudo cp $TMP_DIR/$UIMAGE_NAME $TMP_MOUNT/
sudo cp $TMP_DIR/$SCR_NAME $TMP_MOUNT/
sudo cp $TMP_DIR/$INITRD_NAME $TMP_MOUNT/
echo "done." >&2

echo "Unmounting u-boot partition ..." >&2
sudo umount $TMP_MOUNT
echo "done." >&2

echo "Removing temporary files ..." >&2
rm -rf $TMP_DIR $TMP_MOUNT
echo "done." >&2

echo "All done!" >&2
