; tests/test_alu.asm
        bits 64
        default rel
%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "abi.inc"
        extern cpu_create
        extern cpu_set_x
        extern cpu_get_x
        extern cpu_reset
        extern guest_store_u32
        extern pack_r
        extern pack_i
        extern pack_u
        extern interp_step

        section .bss
cpu:    resq 1

        section .text

; plant insn at reset, set x1 x2, step, compare x3 to edi expected. returns 0/1 in eax
step_x3:
        push    rbx
        push    r12
        mov     r12d, edi               ; expected
        mov     rbx, [rel cpu]
        mov     rdi, rbx
        call    cpu_reset
        mov     rdi, rbx
        mov     esi, 1
        mov     edx, 40
        call    cpu_set_x
        mov     rdi, rbx
        mov     esi, 2
        mov     edx, 7
        call    cpu_set_x
        ; insn in r13d from caller — wait, use r8 from... caller puts insn in esi
        pop     r12
        pop     rbx
        ret

; redo: run_bin(op_id_handler via packed insn in edi, x1, x2, expect_rd=x3)
; rdi=insn esi=x1 edx=x2 ecx=expect
run4:
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     r12d, edi
        mov     r13d, esi
        mov     r14d, edx
        mov     ebx, ecx
        mov     rdi, [rel cpu]
        call    cpu_reset
        mov     rdi, [rel cpu]
        mov     esi, GUEST_RESET
        mov     edx, r12d
        call    guest_store_u32
        test    eax, eax
        jnz     .fail
        mov     rdi, [rel cpu]
        mov     esi, 1
        mov     edx, r13d
        call    cpu_set_x
        mov     rdi, [rel cpu]
        mov     esi, 2
        mov     edx, r14d
        call    cpu_set_x
        mov     rdi, [rel cpu]
        call    interp_step
        mov     rdi, [rel cpu]
        mov     esi, 3
        call    cpu_get_x
        cmp     eax, ebx
        jne     .fail
        xor     eax, eax
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.fail:
        mov     eax, 1
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC test_alu
        push    rbx
        mov     rdi, DEFAULT_MEM_SIZE
        xor     esi, esi
        call    cpu_create
        mov     [rel cpu], rax
        ; add x3, x1, x2  : 40+7=47
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        xor     ecx, ecx
        xor     r8d, r8d
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 40
        mov     edx, 7
        mov     ecx, 47
        call    run4
        test    eax, eax
        jnz     .fail
        ; sub x3, x1, x2 : 40-7=33
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        xor     ecx, ecx
        mov     r8d, F7_SUB
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 40
        mov     edx, 7
        mov     ecx, 33
        call    run4
        test    eax, eax
        jnz     .fail
        ; and x3, x1, x2 : 40 & 7 = 0
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        mov     ecx, F3_AND
        xor     r8d, r8d
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 40
        mov     edx, 7
        xor     ecx, ecx
        call    run4
        test    eax, eax
        jnz     .fail
        ; or x3, x1, x2 : 40|7=47
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        mov     ecx, F3_OR
        xor     r8d, r8d
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 40
        mov     edx, 7
        mov     ecx, 47
        call    run4
        test    eax, eax
        jnz     .fail
        ; xor
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        mov     ecx, F3_XOR
        xor     r8d, r8d
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 40
        mov     edx, 7
        mov     ecx, 47
        call    run4
        test    eax, eax
        jnz     .fail
        ; slt 40 < 7 ? 0
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        mov     ecx, F3_SLT
        xor     r8d, r8d
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 40
        mov     edx, 7
        xor     ecx, ecx
        call    run4
        test    eax, eax
        jnz     .fail
        ; addi x3, x1, -8  → 40-8=32
        mov     edi, 3
        mov     esi, 1
        mov     edx, -8
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        call    pack_i
        mov     edi, eax
        mov     esi, 40
        xor     edx, edx
        mov     ecx, 32
        call    run4
        test    eax, eax
        jnz     .fail
        ; lui x3, 1  → 0x1000
        mov     edi, 3
        mov     esi, 0x1000
        mov     edx, OPC_LUI
        call    pack_u
        mov     edi, eax
        xor     esi, esi
        xor     edx, edx
        mov     ecx, 0x1000
        call    run4
        test    eax, eax
        jnz     .fail
        xor     eax, eax
        pop     rbx
        ret
.fail:
        mov     eax, 1
        pop     rbx
        ret
