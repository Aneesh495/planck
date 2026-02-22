; src/core/exec_mem.asm
; Loads and stores. Functional path hits guest RAM directly.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"

        extern cpu_get_x
        extern cpu_set_x
        extern pc_advance
        extern guest_load_i8
        extern guest_load_i16
        extern guest_load_u8
        extern guest_load_u16
        extern guest_load_u32
        extern guest_store_u8
        extern guest_store_u16
        extern guest_store_u32
        extern trap_load_access
        extern trap_store_access

        section .text

; addr = rs1 + imm  → eax, cpu in rbx, dec in r12
load_addr:
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS1]
        call    cpu_get_x
        add     eax, [r12 + DEC_IMM]
        ret

PROC exec_lb
        push    rbx
        push    r12
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     esi, eax
        mov     rdi, rbx
        mov     rdx, rsp
        push    rsi
        call    guest_load_i8
        pop     rsi
        test    eax, eax
        jnz     .fault
        mov     edx, [rsp]
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        ; esi already addr
        call    trap_load_access
        add     rsp, 8
        pop     r12
        pop     rbx
        ret

PROC exec_lh
        push    rbx
        push    r12
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     esi, eax
        mov     rdi, rbx
        mov     rdx, rsp
        push    rsi
        call    guest_load_i16
        pop     rsi
        test    eax, eax
        jnz     .fault
        mov     edx, [rsp]
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        call    trap_load_access
        add     rsp, 8
        pop     r12
        pop     rbx
        ret

PROC exec_lw
        push    rbx
        push    r12
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     esi, eax
        mov     rdi, rbx
        mov     rdx, rsp
        push    rsi
        call    guest_load_u32
        pop     rsi
        test    eax, eax
        jnz     .fault
        mov     edx, [rsp]
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        call    trap_load_access
        add     rsp, 8
        pop     r12
        pop     rbx
        ret

PROC exec_lbu
        push    rbx
        push    r12
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     esi, eax
        mov     rdi, rbx
        mov     rdx, rsp
        push    rsi
        call    guest_load_u8
        pop     rsi
        test    eax, eax
        jnz     .fault
        mov     edx, [rsp]
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        call    trap_load_access
        add     rsp, 8
        pop     r12
        pop     rbx
        ret

PROC exec_lhu
        push    rbx
        push    r12
        sub     rsp, 8
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     esi, eax
        mov     rdi, rbx
        mov     rdx, rsp
        push    rsi
        call    guest_load_u16
        pop     rsi
        test    eax, eax
        jnz     .fault
        mov     edx, [rsp]
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RD]
        call    cpu_set_x
        mov     rdi, rbx
        call    pc_advance
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        call    trap_load_access
        add     rsp, 8
        pop     r12
        pop     rbx
        ret

PROC exec_sb
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, r13d
        call    guest_store_u8
        test    eax, eax
        jnz     .fault
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        mov     esi, r13d
        call    trap_store_access
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_sh
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, r13d
        call    guest_store_u16
        test    eax, eax
        jnz     .fault
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        mov     esi, r13d
        call    trap_store_access
        pop     r13
        pop     r12
        pop     rbx
        ret

PROC exec_sw
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        call    load_addr
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, [r12 + DEC_RS2]
        call    cpu_get_x
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, r13d
        call    guest_store_u32
        test    eax, eax
        jnz     .fault
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret
.fault:
        mov     rdi, rbx
        mov     esi, r13d
        call    trap_store_access
        pop     r13
        pop     r12
        pop     rbx
        ret
