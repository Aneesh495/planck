%ifndef PLANCK_HASH_INC
%define PLANCK_HASH_INC

; Open-address map. Keys are bytes[len], values are uint64.

HM_CAP              equ 0
HM_USED             equ 4
HM_TOMBS            equ 8
HM_PAD              equ 12
HM_SLOTS            equ 16                ; ptr
HM_SIZE             equ 24

; slot: state:4, klen:4, key:8, val:8  = 24 bytes
SLOT_STATE          equ 0
SLOT_KLEN           equ 4
SLOT_KEY            equ 8
SLOT_VAL            equ 16
SLOT_SIZE           equ 24

%endif
