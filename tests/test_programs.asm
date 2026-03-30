; tests/test_programs.asm
        bits 64
        default rel
%include "macros.inc"
%include "cpu.inc"
%include "abi.inc"
        extern asm_compile
        extern cpu_create
        extern mem_cpy
        extern interp_run

        section .rodata
src:    db "li a0, 0",10,"li a7, 0",10,"ecall",10,0
srclen  equ $ - src - 1

        section .bss
ptr:    resq 1
len:    resq 1
cpu:    resq 1

        section .text
PROC test_programs
        lea     rdi, [rel src]
        mov     esi, srclen
        xor     edx, edx
        lea     rcx, [rel ptr]
        lea     r8, [rel len]
        call    asm_compile
        test    eax, eax
        jnz     .fail
        mov     rdi, DEFAULT_MEM_SIZE
        xor     esi, esi
        call    cpu_create
        mov     [rel cpu], rax
        mov     rdi, [rax + CPU_MEM_BASE]
        mov     rsi, [rel ptr]
        mov     rdx, [rel len]
        call    mem_cpy
        mov     rdi, [rel cpu]
        call    interp_run
        mov     rax, [rel cpu]
        cmp     dword [rax + CPU_HALT], HALT_ECALL_EXIT
        jne     .fail
        cmp     dword [rax + CPU_HALT_CODE], 0
        jne     .fail
        xor     eax, eax
        ret
.fail:
        mov     eax, 1
        ret
