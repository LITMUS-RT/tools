#!/bin/bash

#
# Simple script to push a compiled version of liblitmus2010 to a KVM instance.
# Originally written by Andrea Bastoni.
# Config file support added by Bjoern Brandenburg.

SSH_PORT=2222      # default
SSH_USER=root      # what to log in as
SSH_HOST=localhost # where is the forwarded port?
HOST_LIBLITMUS_DIR="~/liblitmus2010"     # where is the compilation unit
KVM_WORKSPACE="~/" # where to copy the files

# include config file
[ -f ~/.litmus_kvm ] && source ~/.litmus_kvm

#SRC="${SSH_USER}@${SSH_HOST}:${DATA_DIR}${FILE_GLOB}"
#echo scp -P $SSH_PORT ${SRC} ${DOWNLOADS}
#scp -P $SSH_PORT ${SRC} ${DOWNLOADS}


CMD="ssh -l ${SSH_USER} -p ${SSH_PORT}"
TARGET="${SSH_HOST}:${KVM_WORKSPACE}"
echo rsync -ah -z --progress -e "$CMD" ${HOST_LIBLITMUS_DIR} ${TARGET}
rsync -ah -z --progress -e "$CMD" ${HOST_LIBLITMUS_DIR} ${TARGET}
