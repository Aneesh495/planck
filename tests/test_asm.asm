; tests/test_asm.asm  — assemble a tiny program and check bytes
        bits 64
        default rel
%include "macros.inc"
%include "rv32.inc"
        extern asm_compile
        extern pack_i

        section .rodata
src:    db "addi x1, x0, 5",10,"addi x2, x0, 7",10,0
srclen  equ $ - src - 1

        section .bss
ptr:    resq 1
len:    resq 1

        section .text
PROC test_asm
        lea     rdi, [rel src]
        mov     esi, srclen
        xor     edx, edx
        lea     rcx, [rel ptr]
        lea     r8, [rel len]
        call    asm_compile
        test    eax, eax
        jnz     .fail
        cmp     qword [rel len], 8
        jne     .fail
        ; first insn addi x1, x0, 5
        mov     edi, 1
        xor     esi, esi
        mov     edx, 5
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        call    pack_i
        mov     rcx, [rel ptr]
        cmp     [rcx], eax
        jne     .fail
        xor     eax, eax
        ret
.fail:
        mov     eax, 1
        ret
