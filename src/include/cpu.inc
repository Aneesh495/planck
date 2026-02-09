%ifndef PLANCK_CPU_INC
%define PLANCK_CPU_INC

%include "abi.inc"

; cpu_t  — see docs/LAYOUT.md. Keep these numbers identical.

CPU_X               equ 0                 ; 32 qwords
CPU_PC              equ 256
CPU_MCYCLE          equ 264
CPU_MINSTRET        equ 272
CPU_MEM_BASE        equ 280
CPU_MEM_SIZE        equ 288
CPU_HEAP_BRK        equ 296
CPU_STACK_TOP       equ 304
CPU_HALT            equ 312
CPU_HALT_CODE       equ 316
CPU_PRIV            equ 320
CPU_MODE            equ 324
CPU_TRAP_PEND       equ 328
CPU_PAD0            equ 332
CPU_MSTATUS         equ 336
CPU_MIE             equ 344
CPU_MTVEC           equ 352
CPU_MSCRATCH        equ 360
CPU_MEPC            equ 368
CPU_MCAUSE          equ 376
CPU_MTVAL           equ 384
CPU_MIP             equ 392
CPU_ARENA           equ 400
CPU_L1I             equ 408
CPU_L1D             equ 416
CPU_L2              equ 424
CPU_ITLB            equ 432
CPU_DTLB            equ 440
CPU_PRED            equ 448
CPU_OOO             equ 456
CPU_STATS           equ 464
CPU_TRACE           equ 472
CPU_FETCH_PC        equ 480
CPU_SQUASH          equ 488
CPU_PAD1            equ 492
CPU_SQUASH_PC       equ 496
CPU_ENTRY           equ 504
CPU_MAX_INST        equ 512
CPU_MAX_CYCLE       equ 520
CPU_FLAGS           equ 528               ; bit0 = trace, bit1 = stats, bit2 = dump_regs
CPU_PAD2            equ 532
CPU_TRACE_LEN       equ 536
CPU_TRACE_CAP       equ 540
CPU_SIZE            equ 576

CPUF_TRACE          equ 1
CPUF_STATS          equ 2
CPUF_DUMP           equ 4

PRIV_M              equ 3

TRACE_RING_CAP      equ 16
TRACE_ENT_PC        equ 0
TRACE_ENT_INST      equ 4
TRACE_ENT_SIZE      equ 8

; x register helpers: offset of xn is CPU_X + n*8

%endif
