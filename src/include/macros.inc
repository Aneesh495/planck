%ifndef PLANCK_MACROS_INC
%define PLANCK_MACROS_INC

; Planck host helpers. SysV AMD64, NASM, bits 64 assumed by the includer.

%macro ALIGNED 1
    align %1
%endmacro

%macro ENTER 0
    push rbp
    mov  rbp, rsp
%endmacro

%macro LEAVE_RET 0
    mov  rsp, rbp
    pop  rbp
    ret
%endmacro

; Preserve the six callee-saved GPRs. Use around large functions.
%macro SAVE_CALLEE 0
    push rbx
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro REST_CALLEE 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
%endmacro

; Sign-extend a value in a 32-bit register from WIDTH bits.
; SEXT eax, 12  → treat eax[11:0] as signed.
%macro SEXT 2
    shl  %1, (32 - %2)
    sar  %1, (32 - %2)
%endmacro

%macro ZERO32 1
    xor  %1, %1
%endmacro

; Function prologue that also keeps 16-byte alignment with an odd number
; of pushes: we always push rbp, so an extra dummy if we need more.
%macro PROC 1
    global %1
    align 16
%1:
%endmacro

%endif
