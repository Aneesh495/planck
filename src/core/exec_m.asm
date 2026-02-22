; src/core/exec_m.asm
; RV32M. Division by zero and INT_MIN/-1 follow the spec, not x86.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"

        extern cpu_get_x
        extern cpu_set_x
        extern pc_advance

        section .text

; load rs1→r13d rs2→r14d, cpu rbx, dec r12
m_ops:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        mov     r14d, eax
        ret

m_wb:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        jmp     pc_advance

PROC exec_mul
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        mov     eax, r13d
        imul    r14d
        mov     edx, eax                ; low 32
        call    m_wb
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_mulh
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        mov     eax, r13d
        imul    r14d                    ; edx:eax signed 64
        ; edx is high 32
        call    m_wb
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_mulhu
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        mov     eax, r13d
        mul     r14d                    ; edx:eax unsigned
        call    m_wb
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_mulhsu
        ; signed rs1 * unsigned rs2, high 32
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        ; sign-extend rs1 to 64, zero-extend rs2 to 64, imul
        movsxd  rax, r13d
        mov     ecx, r14d
        mov     rdx, rcx
        imul    rdx
        ; rdx:rax is 128; we want bits 63:32 of the 64-bit product
        ; signed*unsigned 32 → 64-bit product is in rax (imul r64)
        ; wait: imul rdx with rax means rax * rdx → rdx:rax 128
        ; 32x32 needs only 64: movsxd rax, r13d; mov ecx, r14d; imul rax, rcx; then shr rax,32
        movsxd  rax, r13d
        mov     ecx, r14d
        imul    rax, rcx
        shr     rax, 32
        mov     edx, eax
        call    m_wb
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_div
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        test    r14d, r14d
        jz      .div0
        cmp     r13d, 0x80000000
        jne     .do
        cmp     r14d, -1
        je      .ovf
.do:
        mov     eax, r13d
        cdq
        idiv    r14d
        mov     edx, eax
        call    m_wb
        jmp     .out
.div0:
        mov     edx, -1
        call    m_wb
        jmp     .out
.ovf:
        mov     edx, 0x80000000
        call    m_wb
.out:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_divu
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        test    r14d, r14d
        jz      .div0
        mov     eax, r13d
        xor     edx, edx
        div     r14d
        mov     edx, eax
        call    m_wb
        jmp     .out
.div0:
        mov     edx, -1
        call    m_wb
.out:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_rem
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        test    r14d, r14d
        jz      .div0
        cmp     r13d, 0x80000000
        jne     .do
        cmp     r14d, -1
        je      .ovf
.do:
        mov     eax, r13d
        cdq
        idiv    r14d
        ; remainder in edx
        call    m_wb
        jmp     .out
.div0:
        mov     edx, r13d
        call    m_wb
        jmp     .out
.ovf:
        xor     edx, edx
        call    m_wb
.out:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_remu
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        call    m_ops
        test    r14d, r14d
        jz      .div0
        mov     eax, r13d
        xor     edx, edx
        div     r14d
        call    m_wb
        jmp     .out
.div0:
        mov     edx, r13d
        call    m_wb
.out:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
