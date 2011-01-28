#!/bin/bash
# Launch a kernel with GDB support.
# Originally written by Andrea Bastoni.
# Config file support and option parsing added by Bjoern Brandenburg.

function info() {
    echo "(ii) $*"
}

while true
do
    case $1 in
	--gdb)
	    shift
	    WANT_GDB=1
	    ;;
	*) # unknown argument
	    break
	    ;;
    esac
done

if [ $# -lt 2 ]; then
	echo "Usage: run_kvm [--gdb] <vmlinuz> <nr cpu> [other kernel parameters]"
	exit 1
fi

SSH_PORT=2222  # default
GDB_PORT=6666  # override in config file
KVM_IMAGE=~/kvm_debian_images/debian_amd64_lib.qcow2

CPU_TYPE=core2duo

# include config file
[ -f ~/.litmus_kvm ] && source ~/.litmus_kvm

info "Simulating $2 CPUs."
info "Running on top of image ${KVM_IMAGE}."
info "Launching kernel $1."
info "Redirecting SSH to port ${SSH_PORT}."

if [ ! -z "$WANT_GDB" ]
then
    info "Opening remote GDB port ${GDB_PORT}."
    GDB_OPT="-gdb tcp::${GDB_PORT} -S"
else
    GDB_OPT=
fi

# Newer versions of KVM may refuse to load a proper serial interface if both -nographic and -serial stdio are specified (koruna does this).
# In such cases, remove "-serial stdio"
qemu-system-x86_64 ${GDB_OPT} -smp $2 -cpu ${CPU_TYPE} -hda ${KVM_IMAGE} -m 2000 -net nic,model=e1000 -net user -k en-us -kernel $1 -append "console=ttyS0 root=/dev/hda1 $3" ro -nographic -serial stdio -redir tcp:${SSH_PORT}::22
