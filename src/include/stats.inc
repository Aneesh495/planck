%ifndef PLANCK_STATS_INC
%define PLANCK_STATS_INC

; Flat counter block pointed to by cpu.stats. All qwords.

ST_FETCH            equ 0
ST_DECODE           equ 8
ST_RENAME           equ 16
ST_ISSUE            equ 24
ST_COMMIT           equ 32
ST_SQUASH           equ 40
ST_STALL_ICMISS     equ 48
ST_STALL_DE         equ 56
ST_STALL_FR         equ 64
ST_STALL_ROB        equ 72
ST_STALL_RS         equ 80
ST_STALL_SB         equ 88
ST_STALL_FU         equ 96
ST_STALL_SCB        equ 104
ST_STALL_RED        equ 112
ST_LSU_REPLAY       equ 120
ST_LSU_FWD          equ 128
ST_LSU_ABLOCK       equ 136
ST_LSU_SBLOCK       equ 144
ST_BR_LOOK          equ 152
ST_BR_TAKEN         equ 160
ST_BR_MIS           equ 168
ST_BR_BIM_WIN       equ 176
ST_BR_GS_WIN        equ 184
ST_BTB_HIT          equ 192
ST_BTB_MISS         equ 200
ST_BTB_ALIAS        equ 208
ST_RAS_HIT          equ 216
ST_RAS_MIS          equ 224
ST_RAS_OVF          equ 232
ST_RAS_UNF          equ 240
ST_WAKEUP_SCAN      equ 248
ST_HOST_TSC         equ 256
ST_SIZE             equ 272

; Histogram of host cycles per interp_step / ooo_tick. 64 buckets of qword counts.
HIST_BUCKETS        equ 64
HIST_SIZE           equ (HIST_BUCKETS * 8)

PRED_BIM            equ 0                 ; 4096 bytes
PRED_GS             equ 4096
PRED_CH             equ 8192
PRED_GHR            equ 12288
PRED_BTB            equ 12296
PRED_RAS            equ 14344             ; 128*16 = 2048, BTB at 12296, +2048=14344
PRED_RAS_TOS        equ 14408             ; RAS 16*4=64, 14344+64=14408
PRED_SIZE           equ 14416

BTB_ENT_SIZE        equ 16
BTB_CAP             equ 128
BTB_TAG             equ 0
BTB_TGT             equ 4
BTB_KIND            equ 8
BTB_VALID           equ 12

BTB_KIND_NONE       equ 0
BTB_KIND_COND       equ 1
BTB_KIND_JAL        equ 2
BTB_KIND_CALL       equ 3
BTB_KIND_RET        equ 4
BTB_KIND_JALR       equ 5

RAS_CAP             equ 16

%endif
