; src/core/exec_alu.asm
; LUI, AUIPC, OP-IMM, OP (non-M).

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"

        extern cpu_get_x
        extern cpu_set_x
        extern pc_advance
        extern trap_illegal

        section .text

; void exec_illegal(cpu*, dec*)
PROC exec_illegal
        mov     esi, [rsi + DEC_RAW]
        jmp     trap_illegal

PROC exec_lui
        push    rbx
        mov     rbx, rdi
        mov     edx, [rsi + DEC_IMM]
        mov     esi, [rsi + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     rbx
        ret

PROC exec_auipc
        push    rbx
        mov     rbx, rdi
        mov     eax, [rdi + CPU_PC]
        add     eax, [rsi + DEC_IMM]
        mov     edx, eax
        mov     esi, [rsi + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     rbx
        ret

PROC exec_addi
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        add     eax, [r12 + DEC_IMM]
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_xori
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        xor     eax, [r12 + DEC_IMM]
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_ori
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        or      eax, [r12 + DEC_IMM]
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_andi
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        and     eax, [r12 + DEC_IMM]
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_slti
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        cmp     eax, [r12 + DEC_IMM]
        setl    al
        movzx   edx, al
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_sltiu
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        cmp     eax, [r12 + DEC_IMM]
        setb    al
        movzx   edx, al
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_slli
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     ecx, [r12 + DEC_IMM]
        and     ecx, 31
        shl     eax, cl
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_srli
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     ecx, [r12 + DEC_IMM]
        and     ecx, 31
        shr     eax, cl
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

PROC exec_srai
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     ecx, [r12 + DEC_IMM]
        and     ecx, 31
        sar     eax, cl
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r12
        pop     rbx
        ret

; ---- R-type -------------------------------------------------------------

PROC exec_add
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        add     eax, r13d
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_sub
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        sub     r13d, eax
        mov     edx, r13d
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_sll
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        mov     ecx, eax
        and     ecx, 31
        shl     r13d, cl
        mov     edx, r13d
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_srl
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        mov     ecx, eax
        and     ecx, 31
        shr     r13d, cl
        mov     edx, r13d
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_sra
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        mov     ecx, eax
        and     ecx, 31
        sar     r13d, cl
        mov     edx, r13d
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_xor
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        xor     eax, r13d
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_or
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        or      eax, r13d
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_and
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        and     eax, r13d
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_slt
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        cmp     r13d, eax
        setl    al
        movzx   edx, al
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_sltu
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        cmp     r13d, eax
        setb    al
        movzx   edx, al
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_fence
        jmp     pc_advance
