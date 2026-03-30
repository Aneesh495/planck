; tests/test_m.asm
        bits 64
        default rel
%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "abi.inc"
        extern cpu_create
        extern cpu_reset
        extern cpu_set_x
        extern cpu_get_x
        extern guest_store_u32
        extern pack_r
        extern interp_step

        section .bss
cpu:    resq 1

        section .text
; rdi=insn esi=x1 edx=x2 ecx=expect_x3
runm:
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
        jne     .f
        xor     eax, eax
        jmp     .o
.f:     mov     eax, 1
.o:     pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC test_m
        mov     rdi, DEFAULT_MEM_SIZE
        xor     esi, esi
        call    cpu_create
        mov     [rel cpu], rax
        ; mul x3, x1, x2  6*7=42
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        xor     ecx, ecx
        mov     r8d, F7_MUL
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 6
        mov     edx, 7
        mov     ecx, 42
        call    runm
        test    eax, eax
        jnz     .fail
        ; div x3, x1, x2  42/7=6
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        mov     ecx, F3_DIV
        mov     r8d, F7_MUL
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 42
        mov     edx, 7
        mov     ecx, 6
        call    runm
        test    eax, eax
        jnz     .fail
        ; div by 0 → -1
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        mov     ecx, F3_DIV
        mov     r8d, F7_MUL
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 42
        xor     edx, edx
        mov     ecx, -1
        call    runm
        test    eax, eax
        jnz     .fail
        ; rem by 0 → dividend
        mov     edi, 3
        mov     esi, 1
        mov     edx, 2
        mov     ecx, F3_REM
        mov     r8d, F7_MUL
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        mov     esi, 42
        xor     edx, edx
        mov     ecx, 42
        call    runm
        test    eax, eax
        jnz     .fail
        xor     eax, eax
        ret
.fail:
        mov     eax, 1
        ret
