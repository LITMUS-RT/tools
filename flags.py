#!/usr/bin/env python

# A small helper script to help decoding flag fields in various kernel
# data structures. VM flags only, for now.

from functools import partial

def get_flags(flag_defs, flag_word):
    flags = []
    for (name, bit) in flag_defs:
        if flag_word & bit:
            flags.append(name)
    return flags

def format_flags(flag_defs, flag_word):
    return " | ".join(get_flags(flag_defs, flag_word))

# Linux Kernel 2.6.32
VM_FLAGS = [
    ("VM_READ", 0x00000001),
    ("VM_WRITE", 0x00000002),
    ("VM_EXEC", 0x00000004),
    ("VM_SHARED", 0x00000008),
    ("VM_MAYREAD", 0x00000010),
    ("VM_MAYWRITE", 0x00000020),
    ("VM_MAYEXEC", 0x00000040),
    ("VM_MAYSHARE", 0x00000080),
    ("VM_GROWSDOWN", 0x00000100),
    ("VM_GROWSUP", 0x00000200),
    ("VM_PFNMAP", 0x00000400),
    ("VM_DENYWRITE", 0x00000800),
    ("VM_EXECUTABLE", 0x00001000),
    ("VM_LOCKED", 0x00002000),
    ("VM_IO", 0x00004000),
    ("VM_SEQ_READ", 0x00008000),
    ("VM_RAND_READ", 0x00010000),
    ("VM_DONTCOPY", 0x00020000),
    ("VM_DONTEXPAND", 0x00040000),
    ("VM_RESERVED", 0x00080000),
    ("VM_ACCOUNT", 0x00100000),
    ("VM_NORESERVE", 0x00200000),
    ("VM_HUGETLB", 0x00400000),
    ("VM_NONLINEAR", 0x00800000),
    ("VM_MAPPED_COPY", 0x01000000),
    ("VM_INSERTPAGE", 0x02000000),
    ("VM_ALWAYSDUMP", 0x04000000),
    ("VM_CAN_NONLINEAR", 0x08000000),
    ("VM_MIXEDMAP", 0x10000000),
    ("VM_SAO", 0x20000000),
    ("VM_PFN_AT_MMAP", 0x40000000),
    ("VM_MERGEABLE", 0x80000000)
    ]


get_vm_flags    = partial(get_flags, VM_FLAGS)
format_vm_flags = partial(format_flags, VM_FLAGS) 


X86_PTE_FLAGS = [
    ("PAGE_BIT_PRESENT", 1 << 0),
    ("PAGE_BIT_RW", 1 << 1),
    ("PAGE_BIT_USER", 1 << 2),
    ("PAGE_BIT_PWT", 1 << 3),
    ("PAGE_BIT_PCD", 1 << 4),
    ("PAGE_BIT_ACCESSED", 1 << 5),
    ("PAGE_BIT_DIRTY", 1 << 6),
    ("PAGE_BIT_PSE", 1 << 7),
    ("PAGE_BIT_PAT", 1 << 7),
    ("PAGE_BIT_GLOBAL", 1 << 8),
    ("PAGE_BIT_UNUSED1", 1 << 9),
    ("PAGE_BIT_IOMAP", 1 << 10),
    ("PAGE_BIT_HIDDEN", 1 << 11),
    ("PAGE_BIT_PAT_LARGE", 1 << 12),
    ("PAGE_BIT_NX", 1 << 63),
]

get_pte_flags    = partial(get_flags, X86_PTE_FLAGS)
format_pte_flags = partial(format_flags, X86_PTE_FLAGS)
