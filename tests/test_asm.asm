; tests/test_asm.asm  — assemble a tiny program and check bytes
        bits 64
        default rel
%include "macros.inc"
%include "rv32.inc"
        extern asm_compile
        extern pack_i
        extern pack_r
        extern pack_b
        extern pack_s

        section .rodata
; 7 instructions, 28 bytes. ABI names on add/mv/bge catch r8 clobber.
src:    db "addi x1, x0, 5",10
        db "add t4, t0, t1",10
        db "mv t0, t1",10
        db "slli x3, x4, 3",10
        db "bge t2, t3, t",10
        db "nop",10
        db "t:",10
        db "nop",10
        db "sw x0, 0(x2)",10
        db "lw x10, 0(x2)",10,0
srclen  equ $ - src - 1

        section .bss
ptr:    resq 1
len:    resq 1

        section .text
PROC test_asm
        push    rbx
        lea     rdi, [rel src]
        mov     esi, srclen
        xor     edx, edx
        lea     rcx, [rel ptr]
        lea     r8, [rel len]
        call    asm_compile
        test    eax, eax
        jnz     .fail
        cmp     qword [rel len], 36
        jne     .fail
        mov     rbx, [rel ptr]

        ; addi x1, x0, 5
        mov     edi, 1
        xor     esi, esi
        mov     edx, 5
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        call    pack_i
        cmp     [rbx], eax
        jne     .fail

        ; add t4, t0, t1  → add x29, x5, x6
        mov     edi, 29
        mov     esi, 5
        mov     edx, 6
        xor     ecx, ecx
        xor     r8d, r8d
        mov     r9d, OPC_OP
        call    pack_r
        cmp     [rbx + 4], eax
        jne     .fail

        ; mv t0, t1 → addi x5, x6, 0
        mov     edi, 5
        mov     esi, 6
        xor     edx, edx
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        call    pack_i
        cmp     [rbx + 8], eax
        jne     .fail

        ; slli x3, x4, 3  → I-type imm = shamt
        mov     edi, 3
        mov     esi, 4
        mov     edx, 3
        mov     ecx, F3_SLLI
        mov     r8d, OPC_OP_IMM
        call    pack_i
        cmp     [rbx + 12], eax
        jne     .fail

        ; bge t2, t3, t  at 0x80000010, t at 0x80000018, off = 8
        mov     edi, 7
        mov     esi, 28
        mov     edx, 8
        mov     ecx, F3_BGE
        mov     r8d, OPC_BRANCH
        call    pack_b
        cmp     [rbx + 16], eax
        jne     .fail

        ; sw x0, 0(x2)
        mov     edi, 2                  ; rs1
        xor     esi, esi                ; rs2
        xor     edx, edx                ; imm
        mov     ecx, F3_SW
        mov     r8d, OPC_STORE
        call    pack_s
        cmp     [rbx + 28], eax
        jne     .fail

        ; lw x10, 0(x2)
        mov     edi, 10
        mov     esi, 2
        xor     edx, edx
        mov     ecx, F3_LW
        mov     r8d, OPC_LOAD
        call    pack_i
        cmp     [rbx + 32], eax
        jne     .fail

        xor     eax, eax
        pop     rbx
        ret
.fail:
        mov     eax, 1
        pop     rbx
        ret
