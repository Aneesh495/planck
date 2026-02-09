; src/host/die.asm
; Fatal host errors. One line on stderr, then _exit(1).

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"

        extern sys_write
        extern sys_exit
        extern str_len

        section .rodata
prefix: db "planck: ",0
nl:     db 10

        section .text

; void host_die(const char *msg)
PROC host_die
        push    rbx
        mov     rbx, rdi
        mov     edi, STDERR_FILENO
        lea     rsi, [rel prefix]
        mov     edx, 8
        call    sys_write
        mov     rdi, rbx
        call    str_len
        mov     rdx, rax
        mov     rsi, rbx
        mov     edi, STDERR_FILENO
        call    sys_write
        mov     edi, STDERR_FILENO
        lea     rsi, [rel nl]
        mov     edx, 1
        call    sys_write
        mov     edi, 1
        call    sys_exit
        pop     rbx
        ret

; void host_exit(int code)
PROC host_exit
        call    sys_exit
        ret
