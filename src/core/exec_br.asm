; src/core/exec_br.asm
; Branches, JAL, JALR.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"

        extern cpu_get_x
        extern cpu_set_x
        extern pc_advance

        section .text

; compare rs1, rs2. ZF/SF/CF as cmp left, right. rbx=cpu r12=dec
cmp_rs:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        cmp     r13d, eax
        ret

taken:
        mov     eax, [rbx + CPU_PC]
        add     eax, [r12 + DEC_IMM]
        mov     [rbx + CPU_PC], rax
        ret

not_taken:
        mov     rdi, rbx
        jmp     pc_advance

PROC exec_beq
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    cmp_rs
        jne     .no
        call    taken
        jmp     .out
.no:    call    not_taken
.out:   pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_bne
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    cmp_rs
        je      .no
        call    taken
        jmp     .out
.no:    call    not_taken
.out:   pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_blt
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    cmp_rs
        jge     .no
        call    taken
        jmp     .out
.no:    call    not_taken
.out:   pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_bge
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    cmp_rs
        jl      .no
        call    taken
        jmp     .out
.no:    call    not_taken
.out:   pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_bltu
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    cmp_rs
        jae     .no
        call    taken
        jmp     .out
.no:    call    not_taken
.out:   pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_bgeu
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    cmp_rs
        jb      .no
        call    taken
        jmp     .out
.no:    call    not_taken
.out:   pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_jal
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rsi
        mov     eax, [rbx + CPU_PC]
        add     eax, 4
        mov     edx, eax
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     eax, [rbx + CPU_PC]
        add     eax, [r12 + DEC_IMM]
        mov     [rbx + CPU_PC], rax
        pop     r12
        pop     rbx
        ret

PROC exec_jalr
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     r13d, [rbx + CPU_PC]
        add     r13d, 4                 ; link
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        add     eax, [r12 + DEC_IMM]
        and     eax, ~1
        mov     [rbx + CPU_PC], rax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        mov     edx, r13d
        call    cpu_set_x
        pop     r13
        pop     r12
        pop     rbx
        ret
