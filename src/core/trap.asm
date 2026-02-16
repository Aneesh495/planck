; src/core/trap.asm
; Precise traps for the functional core. OoO takes the same helpers at commit.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "abi.inc"

        extern cpu_halt

        section .text

; void trap_take(cpu*, uint32 cause, uint32 tval)
; mepc = current pc (faulting insn). If mtvec==0, halt. Else pc=mtvec.
PROC trap_take
        push    rbx
        mov     rbx, rdi
        mov     eax, [rbx + CPU_PC]
        mov     [rbx + CPU_MEPC], rax
        mov     eax, edx
        mov     [rbx + CPU_MTVAL], rax
        mov     eax, esi
        mov     [rbx + CPU_MCAUSE], rax
        ; mstatus: MPIE = MIE, MIE = 0, MPP = M
        mov     rax, [rbx + CPU_MSTATUS]
        mov     ecx, eax
        and     ecx, MSTATUS_MIE
        shl     ecx, 4                  ; bit 3 → bit 7
        and     rax, ~MSTATUS_MIE
        and     rax, ~MSTATUS_MPIE
        or      rax, rcx
        or      rax, MSTATUS_MPP_M
        mov     [rbx + CPU_MSTATUS], rax
        mov     rax, [rbx + CPU_MTVEC]
        test    rax, rax
        jz      .halt
        and     eax, ~1                 ; direct mode only
        mov     [rbx + CPU_PC], rax
        pop     rbx
        ret
.halt:
        mov     rdi, rbx
        mov     esi, HALT_FAULT
        mov     edx, [rbx + CPU_MCAUSE]
        call    cpu_halt
        pop     rbx
        ret

; void trap_illegal(cpu*, uint32 inst)
PROC trap_illegal
        mov     edx, esi
        mov     esi, CAUSE_ILLEGAL_INST
        jmp     trap_take

; void trap_fetch(cpu*, uint32 addr)
PROC trap_fetch_access
        mov     edx, esi
        mov     esi, CAUSE_FETCH_ACCESS
        jmp     trap_take

PROC trap_load_access
        mov     edx, esi
        mov     esi, CAUSE_LOAD_ACCESS
        jmp     trap_take

PROC trap_store_access
        mov     edx, esi
        mov     esi, CAUSE_STORE_ACCESS
        jmp     trap_take

PROC trap_breakpoint
        xor     edx, edx
        mov     esi, CAUSE_BREAKPOINT
        jmp     trap_take

PROC trap_ecall
        xor     edx, edx
        mov     esi, CAUSE_ECALL_M
        jmp     trap_take

; void exec_mret(cpu*, dec*)  — also used from exec_sys
PROC exec_mret
        ; pc = mepc
        mov     rax, [rdi + CPU_MEPC]
        and     eax, ~1
        mov     [rdi + CPU_PC], rax
        ; MIE = MPIE, MPIE = 1
        mov     rax, [rdi + CPU_MSTATUS]
        mov     ecx, eax
        and     ecx, MSTATUS_MPIE
        shr     ecx, 4
        and     rax, ~MSTATUS_MIE
        or      rax, rcx
        or      rax, MSTATUS_MPIE
        mov     [rdi + CPU_MSTATUS], rax
        ret
