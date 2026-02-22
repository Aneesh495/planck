; src/core/exec_sys.asm
; ECALL, EBREAK, CSR*, MRET.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "abi.inc"

        extern cpu_get_x
        extern cpu_set_x
        extern pc_advance
        extern cpu_halt
        extern trap_breakpoint
        extern trap_ecall
        extern trap_illegal
        extern csr_read
        extern csr_write
        extern monitor_ecall
        extern exec_mret

        section .text

PROC exec_ebreak
        jmp     trap_breakpoint

PROC exec_ecall
        jmp     monitor_ecall

; CSR: read old, compute new, write if required, wb old to rd, pc+4
; csrrw: new = rs1, always write
; csrrs: new = old | rs1, write if rs1 != 0
; csrrc: new = old & ~rs1, write if rs1 != 0
; immediate forms use zimm = rs1 field

PROC exec_csrrw
        push    rbx
        push    r12
        push    r13
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_CSR]
        mov     rdx, rsp
        call    csr_read
        test    eax, eax
        jnz     .ill
        mov     r13d, [rsp]             ; old
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     rdi, rbx
        mov     esi, [r12 + DEC_CSR]
        mov     edx, eax
        call    csr_write
        test    eax, eax
        jnz     .ill
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        mov     edx, r13d
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret
.ill:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RAW]
        call    trap_illegal
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_csrrs
        push    rbx
        push    r12
        push    r13
        push    r14
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_CSR]
        mov     rdx, rsp
        call    csr_read
        test    eax, eax
        jnz     .ill
        mov     r13d, [rsp]
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r14d, eax
        test    r14d, r14d
        jz      .nowr
        mov     edx, r13d
        or      edx, r14d
        mov     rdi, rbx
        mov     esi, [r12 + DEC_CSR]
        call    csr_write
        test    eax, eax
        jnz     .ill
.nowr:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        mov     edx, r13d
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.ill:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RAW]
        call    trap_illegal
        add     rsp, 8
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_csrrc
        push    rbx
        push    r12
        push    r13
        push    r14
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_CSR]
        mov     rdx, rsp
        call    csr_read
        test    eax, eax
        jnz     .ill
        mov     r13d, [rsp]
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r14d, eax
        test    r14d, r14d
        jz      .nowr
        mov     edx, r14d
        not     edx
        and     edx, r13d
        mov     rdi, rbx
        mov     esi, [r12 + DEC_CSR]
        call    csr_write
        test    eax, eax
        jnz     .ill
.nowr:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        mov     edx, r13d
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.ill:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RAW]
        call    trap_illegal
        add     rsp, 8
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_csrrwi
        push    rbx
        push    r12
        push    r13
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_CSR]
        mov     rdx, rsp
        call    csr_read
        test    eax, eax
        jnz     .ill
        mov     r13d, [rsp]
        mov     edx, [r12 + DEC_RS1]    ; zimm
        mov     rdi, rbx
        mov     esi, [r12 + DEC_CSR]
        call    csr_write
        test    eax, eax
        jnz     .ill
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        mov     edx, r13d
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret
.ill:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RAW]
        call    trap_illegal
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_csrrsi
        push    rbx
        push    r12
        push    r13
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_CSR]
        mov     rdx, rsp
        call    csr_read
        test    eax, eax
        jnz     .ill
        mov     r13d, [rsp]
        mov     eax, [r12 + DEC_RS1]
        test    eax, eax
        jz      .nowr
        or      eax, r13d
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_CSR]
        call    csr_write
        test    eax, eax
        jnz     .ill
.nowr:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        mov     edx, r13d
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret
.ill:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RAW]
        call    trap_illegal
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_csrrci
        push    rbx
        push    r12
        push    r13
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, [r12 + DEC_CSR]
        mov     rdx, rsp
        call    csr_read
        test    eax, eax
        jnz     .ill
        mov     r13d, [rsp]
        mov     eax, [r12 + DEC_RS1]
        test    eax, eax
        jz      .nowr
        not     eax
        and     eax, r13d
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_CSR]
        call    csr_write
        test    eax, eax
        jnz     .ill
.nowr:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        mov     edx, r13d
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret
.ill:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RAW]
        call    trap_illegal
        add     rsp, 8
        pop     r13
        pop     r12
        pop     rbx
        ret
