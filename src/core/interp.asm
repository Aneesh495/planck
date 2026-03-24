; src/core/interp.asm
; Functional run loop: fetch, decode, execute, retire.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "abi.inc"
%include "stats.inc"

        extern guest_load_u32
        extern decode_inst
        extern exec_decoded
        extern trap_fetch_access
        extern trap_illegal
        extern trap_take
        extern cpu_trace_push
        extern tsc_now
        extern hist_add

        section .bss
        align 16
dec_tmp:        resb DEC_SIZEOF

        section .text

; int interp_step(cpu*)  — 0 continue, 1 halted
PROC interp_step
        push    rbx
        sub     rsp, 16
        mov     rbx, rdi
        cmp     dword [rbx + CPU_HALT], 0
        jne     .halted
        mov     rax, [rbx + CPU_MINSTRET]
        cmp     rax, [rbx + CPU_MAX_INST]
        jae     .maxinst
        ; fetch
        mov     esi, [rbx + CPU_PC]
        test    esi, 3
        jnz     .misal
        lea     rdx, [rsp]              ; out inst
        mov     rdi, rbx
        call    guest_load_u32
        test    eax, eax
        jnz     .ffault
        mov     r8d, [rsp]              ; inst
        ; decode
        mov     edi, r8d
        mov     esi, [rbx + CPU_PC]
        lea     rdx, [rel dec_tmp]
        push    r8
        call    decode_inst
        pop     r8
        cmp     dword [rel dec_tmp + DEC_ILLEGAL], 0
        jne     .ill
        ; optional trace
        test    dword [rbx + CPU_FLAGS], CPUF_TRACE
        jz      .notr
        mov     rdi, rbx
        mov     esi, [rbx + CPU_PC]
        mov     edx, r8d
        call    cpu_trace_push
.notr:
        mov     rdi, rbx
        lea     rsi, [rel dec_tmp]
        call    exec_decoded
        ; x0 hardwire
        mov     qword [rbx + CPU_X], 0
        inc     qword [rbx + CPU_MINSTRET]
        cmp     dword [rbx + CPU_MODE], MODE_OOO
        je      .nocyc
        inc     qword [rbx + CPU_MCYCLE]
.nocyc:
        xor     eax, eax
        cmp     dword [rbx + CPU_HALT], 0
        setne   al
        add     rsp, 16
        pop     rbx
        ret
.halted:
        mov     eax, 1
        add     rsp, 16
        pop     rbx
        ret
.maxinst:
        mov     dword [rbx + CPU_HALT], HALT_MAX_INST
        mov     eax, 1
        add     rsp, 16
        pop     rbx
        ret
.misal:
        mov     rdi, rbx
        mov     esi, CAUSE_MISALIGNED_FETCH
        mov     edx, [rbx + CPU_PC]
        call    trap_take
        mov     eax, 1
        add     rsp, 16
        pop     rbx
        ret
.ffault:
        mov     rdi, rbx
        mov     esi, [rbx + CPU_PC]
        call    trap_fetch_access
        mov     eax, 1
        add     rsp, 16
        pop     rbx
        ret
.ill:
        mov     rdi, rbx
        mov     esi, r8d
        call    trap_illegal
        mov     eax, 1
        add     rsp, 16
        pop     rbx
        ret

; void interp_run(cpu*)
PROC interp_run
        push    rbx
        mov     rbx, rdi
.loop:
        mov     rdi, rbx
        call    interp_step
        test    eax, eax
        jz      .loop
        pop     rbx
        ret
