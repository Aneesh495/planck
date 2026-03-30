; tests/test_decode.asm
        bits 64
        default rel
%include "macros.inc"
%include "rv32.inc"
        extern decode_inst
        extern pack_r
        extern pack_i

        section .bss
        align 16
d:      resb DEC_SIZEOF

        section .text
PROC test_decode
        push    rbx
        ; addi x1, x0, 5  → pack_i(1, 0, 5, 0, OP_IMM)
        mov     edi, 1
        xor     esi, esi
        mov     edx, 5
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        call    pack_i
        mov     edi, eax
        xor     esi, esi
        lea     rdx, [rel d]
        call    decode_inst
        test    eax, eax
        jnz     .fail
        cmp     dword [rel d + DEC_ID], ID_ADDI
        jne     .fail
        cmp     dword [rel d + DEC_RD], 1
        jne     .fail
        cmp     dword [rel d + DEC_RS1], 0
        jne     .fail
        cmp     dword [rel d + DEC_IMM], 5
        jne     .fail
        ; add x3, x1, x2
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        xor     ecx, ecx
        xor     r8d, r8d
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        xor     esi, esi
        lea     rdx, [rel d]
        call    decode_inst
        cmp     dword [rel d + DEC_ID], ID_ADD
        jne     .fail
        cmp     dword [rel d + DEC_RD], 3
        jne     .fail
        ; illegal opcode 0
        xor     edi, edi
        xor     esi, esi
        lea     rdx, [rel d]
        call    decode_inst
        cmp     dword [rel d + DEC_ILLEGAL], 1
        jne     .fail
        xor     eax, eax
        pop     rbx
        ret
.fail:
        mov     eax, 1
        pop     rbx
        ret
