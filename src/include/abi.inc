%ifndef PLANCK_ABI_INC
%define PLANCK_ABI_INC

; Host-wide constants that are not ISA and not CPU-offset.

PLANCK_VERSION_MAJ  equ 0
PLANCK_VERSION_MIN  equ 1
PLANCK_VERSION_PAT  equ 0

; Default guest RAM and arena slack.
DEFAULT_MEM_SIZE    equ (64 * 1024 * 1024)
ARENA_SLACK         equ (4 * 1024 * 1024)
DEFAULT_ARENA       equ (DEFAULT_MEM_SIZE + ARENA_SLACK)

GUEST_RESET         equ 0x80000000
GUEST_DATA_HINT     equ 0x80010000
GUEST_HEAP_BASE     equ 0x80100000

MAX_SOURCE_BYTES    equ (2 * 1024 * 1024)
IO_SCRATCH          equ 4096

; CLI mode
MODE_FUNCTIONAL     equ 0
MODE_OOO            equ 1

; Halt reasons
HALT_NONE           equ 0
HALT_ECALL_EXIT     equ 1
HALT_EBREAK         equ 2
HALT_FAULT          equ 3
HALT_MAX_INST       equ 4
HALT_MAX_CYCLE      equ 5
HALT_HOST           equ 6

; Hash map
HASH_EMPTY          equ 0
HASH_LIVE           equ 1
HASH_TOMB           equ 2

%endif
