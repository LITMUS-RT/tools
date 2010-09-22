#!/bin/bash
#
# Simple script to download files from a KVM image to the local system.
# Originally written by Andrea Bastoni.
# Config file support added by Bjoern Brandenburg.

SSH_PORT=2222      # default
SSH_USER=root      # what to log in as
SSH_HOST=localhost # where is the forwarded port?
DATA_DIR="~/liblitmus2010/" # where are the traces in the image?
FILE_GLOB="test*.bin" # which files to copy
DOWNLOADS=.        # where to copy the files

# include config file
[ -f ~/.litmus_kvm ] && source ~/.litmus_kvm

#SRC="${SSH_USER}@${SSH_HOST}:${DATA_DIR}${FILE_GLOB}"
#echo scp -P $SSH_PORT ${SRC} ${DOWNLOADS}
#scp -P $SSH_PORT ${SRC} ${DOWNLOADS}


CMD="ssh -l ${SSH_USER} -p ${SSH_PORT}"
SRC="${SSH_HOST}:${DATA_DIR}${FILE_GLOB}"
echo rsync -ah -z --progress -e "$CMD" ${SRC} ${DOWNLOADS}
rsync -ah -z --progress -e "$CMD" ${SRC} ${DOWNLOADS}
