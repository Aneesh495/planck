%ifndef PLANCK_CACHE_INC
%define PLANCK_CACHE_INC

; Geometry. Line size is 64 everywhere.

LINE_SHIFT          equ 6
LINE_SIZE           equ 64
LINE_MASK           equ 63

PAGE_SHIFT          equ 12
PAGE_SIZE           equ 4096
PAGE_MASK           equ 4095

; L1I: 16 KiB, 2-way, 128 sets. index = PA[12:6]
L1I_WAYS            equ 2
L1I_SETS            equ 128
L1I_INDEX_SHIFT     equ 6
L1I_INDEX_MASK      equ 127
L1I_TAG_SHIFT       equ 13
L1I_HIT_LAT         equ 1
L1I_MSHR            equ 2

; L1D: 16 KiB, 4-way, 64 sets. index = PA[11:6]
L1D_WAYS            equ 4
L1D_SETS            equ 64
L1D_INDEX_SHIFT     equ 6
L1D_INDEX_MASK      equ 63
L1D_TAG_SHIFT       equ 12
L1D_HIT_LAT         equ 3
L1D_MSHR            equ 4

; L2: 256 KiB, 8-way, 512 sets. index = PA[14:6]
L2_WAYS             equ 8
L2_SETS             equ 512
L2_INDEX_SHIFT      equ 6
L2_INDEX_MASK       equ 511
L2_TAG_SHIFT        equ 15
L2_HIT_LAT          equ 12
L2_MSHR             equ 8

DRAM_LAT            equ 100
TLB_MISS_LAT        equ 8
TLB_ENTRIES         equ 32

; Tag record, 8 bytes: tag:32, valid:8, dirty:8, lru:16
TAG_TAG             equ 0
TAG_VALID           equ 4
TAG_DIRTY           equ 5
TAG_LRU             equ 6
TAG_SIZE            equ 8

; MSHR slot, 16 bytes
MSHR_VALID          equ 0
MSHR_REM            equ 4
MSHR_PA             equ 8
MSHR_SIZE           equ 16

; Generic cache header pointed to by cpu.l1i / l1d / l2
;   ways, sets, tag_shift, index_mask, hit_lat, mshr_n, then pointers
CH_WAYS             equ 0
CH_SETS             equ 4
CH_TAG_SHIFT        equ 8
CH_INDEX_MASK       equ 12
CH_HIT_LAT          equ 16
CH_MSHR_N           equ 20
CH_KIND             equ 24            ; 0=I 1=D 2=L2
CH_PAD              equ 28
CH_TAGS             equ 32            ; ptr  sets*ways*TAG_SIZE
CH_DATA             equ 40            ; ptr  sets*ways*LINE_SIZE
CH_MSHR             equ 48
CH_PLRU             equ 56            ; ptr  one byte per set (L2)
CH_HITS             equ 64
CH_MISSES           equ 72
CH_WRITEBACKS       equ 80
CH_MSHR_FULL        equ 88
CH_BACKINVAL        equ 96
CH_SMC              equ 104
CH_SIZE             equ 128

KIND_I              equ 0
KIND_D              equ 1
KIND_L2             equ 2

; TLB entry 16 bytes: vpn, ppn, valid, lru, perm, pad
TLB_VPN             equ 0
TLB_PPN             equ 4
TLB_VALID           equ 8
TLB_LRU             equ 9
TLB_PERM            equ 10
TLB_PAD             equ 11
TLB_ENT_SIZE        equ 16

TLB_HITS            equ (TLB_ENTRIES * TLB_ENT_SIZE)
TLB_MISSES          equ (TLB_HITS + 8)
TLB_SIZE            equ (TLB_MISSES + 8)

PERM_R              equ 1
PERM_W              equ 2
PERM_X              equ 4
PERM_RWX            equ 7

%endif
