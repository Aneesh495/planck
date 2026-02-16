; src/core/csr.asm
; Machine-mode CSR read/write. Unknown addresses are illegal (return -1).

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"

        section .text

; int csr_read(cpu*, uint32 addr, uint32 *out)  0 ok, -1 illegal
PROC csr_read
        mov     eax, esi
        cmp     eax, CSR_MSTATUS
        je      .mstatus
        cmp     eax, CSR_MIE
        je      .mie
        cmp     eax, CSR_MTVEC
        je      .mtvec
        cmp     eax, CSR_MSCRATCH
        je      .mscratch
        cmp     eax, CSR_MEPC
        je      .mepc
        cmp     eax, CSR_MCAUSE
        je      .mcause
        cmp     eax, CSR_MTVAL
        je      .mtval
        cmp     eax, CSR_MIP
        je      .mip
        cmp     eax, CSR_MCYCLE
        je      .mcycle
        cmp     eax, CSR_CYCLE
        je      .mcycle
        cmp     eax, CSR_MINSTRET
        je      .minstret
        cmp     eax, CSR_INSTRET
        je      .minstret
        cmp     eax, CSR_MCYCLEH
        je      .mcycleh
        cmp     eax, CSR_CYCLEH
        je      .mcycleh
        cmp     eax, CSR_MINSTRETH
        je      .minstreth
        cmp     eax, CSR_INSTRETH
        je      .minstreth
        cmp     eax, CSR_MVENDORID
        je      .zero
        cmp     eax, CSR_MARCHID
        je      .zero
        cmp     eax, CSR_MHARTID
        je      .zero
        cmp     eax, CSR_MIMPID
        je      .impid
        mov     eax, -1
        ret
.mstatus:
        mov     eax, [rdi + CPU_MSTATUS]
        jmp     .ok
.mie:
        mov     eax, [rdi + CPU_MIE]
        jmp     .ok
.mtvec:
        mov     eax, [rdi + CPU_MTVEC]
        jmp     .ok
.mscratch:
        mov     eax, [rdi + CPU_MSCRATCH]
        jmp     .ok
.mepc:
        mov     eax, [rdi + CPU_MEPC]
        jmp     .ok
.mcause:
        mov     eax, [rdi + CPU_MCAUSE]
        jmp     .ok
.mtval:
        mov     eax, [rdi + CPU_MTVAL]
        jmp     .ok
.mip:
        mov     eax, [rdi + CPU_MIP]
        jmp     .ok
.mcycle:
        mov     eax, [rdi + CPU_MCYCLE]
        jmp     .ok
.mcycleh:
        mov     rax, [rdi + CPU_MCYCLE]
        shr     rax, 32
        jmp     .ok
.minstret:
        mov     eax, [rdi + CPU_MINSTRET]
        jmp     .ok
.minstreth:
        mov     rax, [rdi + CPU_MINSTRET]
        shr     rax, 32
        jmp     .ok
.zero:
        xor     eax, eax
        jmp     .ok
.impid:
        mov     eax, MIMPID_PLNK
.ok:
        mov     [rdx], eax
        xor     eax, eax
        ret

; int csr_write(cpu*, uint32 addr, uint32 val)  0 ok, -1 illegal
PROC csr_write
        mov     eax, esi
        ; RO CSRs
        cmp     eax, CSR_MVENDORID
        je      .ill
        cmp     eax, CSR_MARCHID
        je      .ill
        cmp     eax, CSR_MIMPID
        je      .ill
        cmp     eax, CSR_MHARTID
        je      .ill
        cmp     eax, CSR_CYCLE
        je      .ill
        cmp     eax, CSR_CYCLEH
        je      .ill
        cmp     eax, CSR_INSTRET
        je      .ill
        cmp     eax, CSR_INSTRETH
        je      .ill
        cmp     eax, CSR_MSTATUS
        je      .mstatus
        cmp     eax, CSR_MIE
        je      .mie
        cmp     eax, CSR_MTVEC
        je      .mtvec
        cmp     eax, CSR_MSCRATCH
        je      .mscratch
        cmp     eax, CSR_MEPC
        je      .mepc
        cmp     eax, CSR_MCAUSE
        je      .mcause
        cmp     eax, CSR_MTVAL
        je      .mtval
        cmp     eax, CSR_MIP
        je      .mip
        cmp     eax, CSR_MCYCLE
        je      .mcycle
        cmp     eax, CSR_MINSTRET
        je      .minstret
        cmp     eax, CSR_MCYCLEH
        je      .mcycleh
        cmp     eax, CSR_MINSTRETH
        je      .minstreth
.ill:
        mov     eax, -1
        ret
.mstatus:
        mov     eax, edx
        and     eax, (MSTATUS_MIE | MSTATUS_MPIE | MSTATUS_MPP)
        or      eax, MSTATUS_MPP_M      ; force MPP=M
        mov     [rdi + CPU_MSTATUS], rax
        xor     eax, eax
        ret
.mie:
        mov     eax, edx
        mov     [rdi + CPU_MIE], rax
        xor     eax, eax
        ret
.mtvec:
        test    edx, 1
        jnz     .ill                    ; vectored rejected
        mov     eax, edx
        and     eax, ~1
        mov     [rdi + CPU_MTVEC], rax
        xor     eax, eax
        ret
.mscratch:
        mov     eax, edx
        mov     [rdi + CPU_MSCRATCH], rax
        xor     eax, eax
        ret
.mepc:
        mov     eax, edx
        and     eax, ~1
        mov     [rdi + CPU_MEPC], rax
        xor     eax, eax
        ret
.mcause:
        mov     eax, edx
        mov     [rdi + CPU_MCAUSE], rax
        xor     eax, eax
        ret
.mtval:
        mov     eax, edx
        mov     [rdi + CPU_MTVAL], rax
        xor     eax, eax
        ret
.mip:
        mov     eax, edx
        mov     [rdi + CPU_MIP], rax
        xor     eax, eax
        ret
.mcycle:
        mov     rax, [rdi + CPU_MCYCLE]
        mov     eax, edx                ; keep high? replace low 32, keep high
        ; rebuild: high from old, low = edx
        mov     rcx, [rdi + CPU_MCYCLE]
        shr     rcx, 32
        shl     rcx, 32
        mov     eax, edx
        or      rax, rcx
        mov     [rdi + CPU_MCYCLE], rax
        xor     eax, eax
        ret
.minstret:
        mov     rcx, [rdi + CPU_MINSTRET]
        shr     rcx, 32
        shl     rcx, 32
        mov     eax, edx
        or      rax, rcx
        mov     [rdi + CPU_MINSTRET], rax
        xor     eax, eax
        ret
.mcycleh:
        mov     rcx, [rdi + CPU_MCYCLE]
        mov     ecx, ecx                ; low 32
        mov     eax, edx
        shl     rax, 32
        or      rax, rcx
        mov     [rdi + CPU_MCYCLE], rax
        xor     eax, eax
        ret
.minstreth:
        mov     rcx, [rdi + CPU_MINSTRET]
        mov     ecx, ecx
        mov     eax, edx
        shl     rax, 32
        or      rax, rcx
        mov     [rdi + CPU_MINSTRET], rax
        xor     eax, eax
        ret
