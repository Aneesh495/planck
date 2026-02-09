; src/host/time.asm
; Host clocks: lfence+rdtsc and clock_gettime. Histogram is log2 buckets.

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"
%include "stats.inc"

        extern sys_clock_gettime

        section .text

; uint64 tsc_now(void)
PROC tsc_now
        lfence
        rdtsc
        lfence
        shl     rdx, 32
        or      rax, rdx
        ret

; uint64 monotonic_ns(void)
PROC monotonic_ns
        sub     rsp, 24
        mov     edi, CLOCK_MONOTONIC
        mov     rsi, rsp
        call    sys_clock_gettime
        ; timespec: tv_sec i64, tv_nsec i64
        mov     rax, [rsp]
        mov     rcx, 1000000000
        mul     rcx
        add     rax, [rsp+8]
        add     rsp, 24
        ret

; void hist_add(uint64 *buckets, uint64 delta)
; bucket = min(63, floor(log2(delta)))  with delta==0 → bucket 0
PROC hist_add
        mov     rax, rsi
        test    rax, rax
        jz      .z
        bsr     rcx, rax                ; index of highest set bit
        cmp     ecx, 63
        jbe     .ok
        mov     ecx, 63
.ok:
        inc     qword [rdi + rcx*8]
        ret
.z:
        inc     qword [rdi]
        ret

; uint64 tsc_delta(uint64 start)  — now - start, saturating at 0
PROC tsc_delta
        push    rdi
        call    tsc_now
        pop     rdi
        sub     rax, rdi
        jnc     .ok
        xor     eax, eax
.ok:
        ret
