; src/stats/report.asm
        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "cache.inc"
%include "stats.inc"
%include "syscall.inc"

        extern io_cstr
        extern io_nl
        extern io_udec
        extern io_sp

        section .rodata
h_stats:        db "---- planck stats ----",10,0
h_inst:         db "minstret        ",0
h_cyc:          db "mcycle          ",0
h_ipc:          db "ipc (x1000)     ",0
h_l1i:          db "l1i hits/misses ",0
h_l1d:          db "l1d hits/misses ",0
h_l2:           db "l2  hits/misses ",0
slash:          db " / ",0

        section .text

; void stats_report(cpu*)
PROC stats_report
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     edi, 1
        lea     rsi, [rel h_stats]
        call    io_cstr
        mov     edi, 1
        lea     rsi, [rel h_inst]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [rbx + CPU_MINSTRET]
        xor     edx, edx
        mov     ecx, 10
        call    io_udec
        mov     edi, 1
        call    io_nl
        mov     edi, 1
        lea     rsi, [rel h_cyc]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [rbx + CPU_MCYCLE]
        xor     edx, edx
        mov     ecx, 10
        call    io_udec
        mov     edi, 1
        call    io_nl
        ; ipc * 1000 = minstret * 1000 / mcycle
        mov     edi, 1
        lea     rsi, [rel h_ipc]
        call    io_cstr
        mov     rax, [rbx + CPU_MINSTRET]
        mov     rcx, 1000
        mul     rcx
        mov     rcx, [rbx + CPU_MCYCLE]
        test    rcx, rcx
        jz      .z
        xor     edx, edx
        div     rcx
        jmp     .p
.z:     xor     eax, eax
.p:
        mov     edi, 1
        mov     rsi, rax
        xor     edx, edx
        mov     ecx, 10
        call    io_udec
        mov     edi, 1
        call    io_nl
        ; caches
        mov     r12, [rbx + CPU_L1I]
        test    r12, r12
        jz      .out
        mov     edi, 1
        lea     rsi, [rel h_l1i]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [r12 + CH_HITS]
        call    io_udec
        mov     edi, 1
        lea     rsi, [rel slash]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [r12 + CH_MISSES]
        call    io_udec
        mov     edi, 1
        call    io_nl
        mov     r12, [rbx + CPU_L1D]
        test    r12, r12
        jz      .out
        mov     edi, 1
        lea     rsi, [rel h_l1d]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [r12 + CH_HITS]
        call    io_udec
        mov     edi, 1
        lea     rsi, [rel slash]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [r12 + CH_MISSES]
        call    io_udec
        mov     edi, 1
        call    io_nl
        mov     r12, [rbx + CPU_L2]
        test    r12, r12
        jz      .out
        mov     edi, 1
        lea     rsi, [rel h_l2]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [r12 + CH_HITS]
        call    io_udec
        mov     edi, 1
        lea     rsi, [rel slash]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [r12 + CH_MISSES]
        call    io_udec
        mov     edi, 1
        call    io_nl
.out:
        pop     r12
        pop     rbx
        ret
