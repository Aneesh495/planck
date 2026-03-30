; tests/harness.asm
; `planck test` entry. Each test_* returns 0 on success.

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"

        extern io_cstr
        extern io_nl
        extern io_udec
        extern io_sp

        extern test_hash
        extern test_decode
        extern test_alu
        extern test_m
        extern test_mem
        extern test_branch
        extern test_asm
        extern test_cache
        extern test_programs

        section .rodata
t_ok:           db "ok  ",0
t_fail:         db "FAIL ",0
t_sum:          db "failures: ",0
n_hash:         db "hash",0
n_decode:       db "decode",0
n_alu:          db "alu",0
n_m:            db "muldiv",0
n_mem:          db "mem",0
n_br:           db "branch",0
n_asm:          db "asm",0
n_cache:        db "cache",0
n_prog:         db "programs",0

        section .text

report:
        ; edi = rc, rsi = name
        push    rdi
        push    rsi
        test    edi, edi
        jnz     .f
        mov     edi, 1
        lea     rsi, [rel t_ok]
        call    io_cstr
        jmp     .n
.f:
        mov     edi, 1
        lea     rsi, [rel t_fail]
        call    io_cstr
.n:
        pop     rsi
        mov     edi, 1
        call    io_cstr
        mov     edi, 1
        call    io_nl
        pop     rax
        ret

PROC planck_test
        push    rbx
        xor     ebx, ebx
        call    test_hash
        mov     edi, eax
        lea     rsi, [rel n_hash]
        call    report
        add     ebx, eax
        call    test_decode
        mov     edi, eax
        lea     rsi, [rel n_decode]
        call    report
        add     ebx, eax
        call    test_alu
        mov     edi, eax
        lea     rsi, [rel n_alu]
        call    report
        add     ebx, eax
        call    test_m
        mov     edi, eax
        lea     rsi, [rel n_m]
        call    report
        add     ebx, eax
        call    test_mem
        mov     edi, eax
        lea     rsi, [rel n_mem]
        call    report
        add     ebx, eax
        call    test_branch
        mov     edi, eax
        lea     rsi, [rel n_br]
        call    report
        add     ebx, eax
        call    test_asm
        mov     edi, eax
        lea     rsi, [rel n_asm]
        call    report
        add     ebx, eax
        call    test_cache
        mov     edi, eax
        lea     rsi, [rel n_cache]
        call    report
        add     ebx, eax
        call    test_programs
        mov     edi, eax
        lea     rsi, [rel n_prog]
        call    report
        add     ebx, eax
        mov     edi, 1
        lea     rsi, [rel t_sum]
        call    io_cstr
        mov     edi, 1
        mov     esi, ebx
        xor     edx, edx
        mov     ecx, 10
        call    io_udec
        mov     edi, 1
        call    io_nl
        mov     eax, ebx
        pop     rbx
        ret
