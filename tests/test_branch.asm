; tests/test_branch.asm
        bits 64
        default rel
%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "abi.inc"
        extern cpu_create
        extern cpu_reset
        extern cpu_set_x
        extern cpu_get_pc
        extern guest_store_u32
        extern pack_b
        extern pack_j
        extern interp_step

        section .bss
cpu:    resq 1

        section .text
PROC test_branch
        mov     rdi, DEFAULT_MEM_SIZE
        xor     esi, esi
        call    cpu_create
        mov     [rel cpu], rax
        ; beq x1, x2, +8  with x1==x2 → pc+8
        mov     rdi, [rel cpu]
        call    cpu_reset
        mov     rdi, [rel cpu]
        mov     esi, 1
        mov     edx, 9
        call    cpu_set_x
        mov     rdi, [rel cpu]
        mov     esi, 2
        mov     edx, 9
        call    cpu_set_x
        xor     edi, edi
        ; pack_b rs1=1 rs2=2 imm=8 f3=0 opc=BRANCH
        mov     edi, 1
        mov     esi, 2
        mov     edx, 8
        xor     ecx, ecx
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     rdi, [rel cpu]
        mov     esi, GUEST_RESET
        mov     edx, eax
        call    guest_store_u32
        mov     rdi, [rel cpu]
        call    interp_step
        mov     rdi, [rel cpu]
        call    cpu_get_pc
        cmp     eax, GUEST_RESET + 8
        jne     .fail
        ; bne not taken
        mov     rdi, [rel cpu]
        call    cpu_reset
        mov     rdi, [rel cpu]
        mov     esi, 1
        mov     edx, 9
        call    cpu_set_x
        mov     rdi, [rel cpu]
        mov     esi, 2
        mov     edx, 9
        call    cpu_set_x
        mov     edi, 1
        mov     esi, 2
        mov     edx, 8
        mov     ecx, F3_BNE
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     rdi, [rel cpu]
        mov     esi, GUEST_RESET
        mov     edx, eax
        call    guest_store_u32
        mov     rdi, [rel cpu]
        call    interp_step
        mov     rdi, [rel cpu]
        call    cpu_get_pc
        cmp     eax, GUEST_RESET + 4
        jne     .fail
        ; jal x0, +16
        mov     rdi, [rel cpu]
        call    cpu_reset
        xor     edi, edi
        mov     esi, 16
        mov     edx, OPC_JAL
        call    pack_j
        mov     rdi, [rel cpu]
        mov     esi, GUEST_RESET
        mov     edx, eax
        call    guest_store_u32
        mov     rdi, [rel cpu]
        call    interp_step
        mov     rdi, [rel cpu]
        call    cpu_get_pc
        cmp     eax, GUEST_RESET + 16
        jne     .fail
        xor     eax, eax
        ret
.fail:
        mov     eax, 1
        ret
