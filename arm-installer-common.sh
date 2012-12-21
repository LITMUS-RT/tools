#!/bin/bash

set -e
set -u

# Build host for ARM.
HOST="pound.cs.unc.edu"
# User doing the builds.
USER="cjk"

# Not installed on the U-Boot partition.
ZIMAGE_FILE="zImage"

# Name of the installed files on the U-Boot partition.
UIMAGE_FILE="uImage-litmus"
INITRD_FILE="uInitrd-litmus"
SCRIPT_FILE="boot-litmus.scr"

# Assumes the globals:
#     - KVERSION
#     - CONFIG_FILE - kernel configuration file name (not path)
#     - LOAD_ADDR
#     - ENTRY_PIONT
#
# Assumes UBOOT_PATH is set by the calling script.

TMP_DIR=$(mktemp -d)

# initramfs state directory (Debian/Ubuntu)
INITRAMFS_STATEDIR="/var/lib/initramfs-tools"

# Where the modules live (not in /lib/modules). This is relative to my homedir.
MODULES_PATH="modules"

error() {
	echo "$@" >&2
	exit 1
}

if [ $# -ne 2 ] ; then
	error "Usage: `basename $0` <REMOTE-KDIR> <BOOT-SCRIPT>"
fi

KERN_DIR=$1
BOOT_TXT=$2

if [ ! -f "$BOOT_TXT" ] ; then
	error "Boot script TXT not a file: $BOOT_TXT"
fi

getversion() {
	local version
	set +e
	version=$(ssh $USER@$HOST cat $KERN_DIR/include/config/kernel.release)
	set -e
	if [ "x" = "x$version" ] ; then
		error "Could not determine version"
	fi
	echo "$version"
}

fetchfiles() {
	echo "Fetching files from $HOST ..." >&2
	rsync -P $USER@$HOST:$KERN_DIR/arch/arm/boot/zImage $TMP_DIR/$ZIMAGE_FILE
	rsync -P $USER@$HOST:$KERN_DIR/.config $TMP_DIR/$CONFIG_FILE
	echo "done." >&2

	local remotemodules
	local havemodules
	remotemodules="$MODULES_PATH/$KVERSION/lib/modules/$KVERSION"
	set +e
	ssh $USER@$HOST "test -e $remotemodules"
	havemodules=$?
	set -e
	if [ $havemodules -ne 0 ] ; then
		echo "No modules found." >&2
		if [ -d "/lib/modules/$KVERSION" ] ; then
			echo "Removing old modules ..." >&2
			sudo rm -rf "/lib/modules/$KVERSION"
			echo "done." >&2
		fi
	else
		echo "Copying modules ..." >&2
		sudo rsync -aP --delete $USER@$HOST:$remotemodules /lib/modules/
		echo "done." >&2
	fi
}

mkuboot() {
	echo "Generating kernel u-boot image..." >&2
	mkimage -A arm -O linux -T kernel -C none \
		-a $LOAD_ADDR -e $ENTRY_POINT \
		-d $TMP_DIR/$ZIMAGE_FILE $TMP_DIR/$UIMAGE_FILE >&2
	echo "done." >&2
}

mkscript() {
	echo "Generating u-boot configuration ... " >&2
	mkimage -A arm -T script -C none -d "$BOOT_TXT" $TMP_DIR/$SCRIPT_FILE >&2
	echo "done." >&2
}

moveconfig() {
	echo "Moving config file to /boot ..." >&2
	sudo cp $TMP_DIR/$CONFIG_FILE /boot/
	echo "done." >&2
}

doinitramfs() {
	local initrdimage
	initrdimage="/boot/initrd.img-$KVERSION"

	if [ -e "$INITRAMFS_STATEDIR/$KVERSION" -o -e "$initrdimage" ] ; then
		echo "Removing old initramfs ... " >&2
		sudo update-initramfs -k $KVERSION -d
		echo "done." >&2
	fi

	echo "Creating initramfs (ignore module errors) ... " >&2
	sudo update-initramfs -k $KVERSION -c
	echo "done." >&2
}

mkuinitrd() {
	local initrdimage
	initrdimage="/boot/initrd.img-$KVERSION"

	echo "Making u-boot initrd image ... " >&2
	mkimage -A arm -O linux -T ramdisk -C none \
		-d $initrdimage $TMP_DIR/$INITRD_FILE >&2
	echo "done." >&2
}

copy_to_uboot() {
	echo "Copying files to u-boot partition ..." >&2
	sudo cp $TMP_DIR/$UIMAGE_FILE $UBOOT_PATH/
	sudo cp $TMP_DIR/$SCRIPT_FILE $UBOOT_PATH/
	sudo cp $TMP_DIR/$INITRD_FILE $UBOOT_PATH/
	echo "done." >&2
}

rm_tmp_files() {
	echo "Removing temporary files ..." >&2
	rm -rf $TMP_DIR
	echo "done." >&2
}
