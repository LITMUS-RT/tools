#!/bin/bash

set -e
set -u

GRUBCFG=/etc/grub.d/40_custom

# initramfs state directory (Debian/Ubuntu)
INITRAMFS_STATEDIR="/var/lib/initramfs-tools"

error() {
	echo "$@" >&2
	exit 1
}

if [ $# -ne 1 ] ; then
	error "Usage: `basename $0` <KDIR>"
fi

KERN_DIR=$1

if [ ! -d "$KERN_DIR" ] ; then
	error "Bad kernel directory."
fi

getversion() {
	local version
	version=$(cat $KERN_DIR/include/config/kernel.release)
	if [ "x" = "x$version" ] ; then
		error "Could not determine version"
	fi
	echo "$version"
}

moveconfig() {
	echo "Moving config file to /boot ..." >&2
	sudo cp .config /boot/config-$KVERSION
	echo "done." >&2
}

copyvmlinuz() {
	echo "Copying vmlinuz to /boot ..." >&2
	sudo cp "$KERN_DIR/arch/x86/boot/bzImage" /boot/vmlinuz-$KVERSION
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

installgrubmenuentry() {
	local entryname
	entryname=$1
	sudo tee -a "$GRUBCFG" > /dev/null <<EOF
menuentry '$entryname' --class gnu-linux --class gnu --class os {
	recordfail
	gfxmode \$linux_gfx_mode
	insmod gzio
	insmod part_gpt
	insmod ext2
	set root='(hd0,gpt2)'
	search --no-floppy --fs-uuid --set=root 1550ea21-685f-4e70-922c-e1749db48e24
	linux	/boot/vmlinuz-$KVERSION root=UUID=1550ea21-685f-4e70-922c-e1749db48e24 ro   
	initrd	/boot/initrd.img-$KVERSION
}
EOF
}

KVERSION=$(getversion)

moveconfig
copyvmlinuz
doinitramfs

entryname="LITMUS $KVERSION"
set +e
_unused=$(grep "$entryname" "$GRUBCFG")
retval=$?
set -e
if [ $retval -ne 0 ] ; then
	echo "Installing grub menuentry ..." >&2
	installgrubmenuentry "$entryname"
	echo "done."
else
	echo "Grub menuentry seems to exist already." >&2
fi

sudo update-grub

echo "You need to grub-set-default manually." >&2
