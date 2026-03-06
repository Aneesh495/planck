; src/monitor/ecall.asm
; Guest ecall ABI. Handled at retire in functional mode.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "syscall.inc"
%include "abi.inc"

        extern cpu_get_x
        extern cpu_set_x
        extern cpu_halt
        extern pc_advance
        extern trap_ecall
        extern guest_ok
        extern guest_ptr
        extern sys_write
        extern sys_read
        extern io_cstr
        extern io_nl
        extern io_hex32
        extern io_sp
        extern io_dec

        section .rodata
dump_hdr:       db "gpr dump:",0
xname:          db "x",0

        section .text

; void monitor_ecall(cpu*, dec*)
PROC monitor_ecall
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12, rsi
        mov     esi, 17                 ; a7 = x17
        call    cpu_get_x
        cmp     eax, ECALL_EXIT
        je      .exit
        cmp     eax, ECALL_EXIT93
        je      .exit
        cmp     eax, ECALL_WRITE
        je      .write
        cmp     eax, ECALL_READ
        je      .read
        cmp     eax, ECALL_CYCLE
        je      .cycle
        cmp     eax, ECALL_SBRK
        je      .sbrk
        cmp     eax, ECALL_DUMP
        je      .dump
        mov     rdi, rbx
        call    trap_ecall
        pop     r13
        pop     r12
        pop     rbx
        ret

.exit:
        mov     rdi, rbx
        mov     esi, 10                 ; a0
        call    cpu_get_x
        mov     rdi, rbx
        mov     esi, HALT_ECALL_EXIT
        mov     edx, eax
        call    cpu_halt
        pop     r13
        pop     r12
        pop     rbx
        ret

.write:
        mov     rdi, rbx
        mov     esi, 10
        call    cpu_get_x
        mov     r13d, eax               ; fd
        cmp     r13d, 1
        je      .wfd
        cmp     r13d, 2
        je      .wfd
        mov     rdi, rbx
        mov     esi, 10
        mov     edx, -EBADF
        call    cpu_set_x
        jmp     .adv
.wfd:
        mov     rdi, rbx
        mov     esi, 11                 ; a1 buf
        call    cpu_get_x
        mov     r12d, eax               ; guest buf (reuse r12)
        mov     rdi, rbx
        mov     esi, 12
        call    cpu_get_x
        mov     edx, eax                ; len
        mov     rdi, rbx
        mov     esi, r12d
        call    guest_ok
        test    eax, eax
        jz      .wfault
        mov     rdi, rbx
        mov     esi, r12d
        call    guest_ptr
        mov     rsi, rax
        mov     edi, r13d
        ; rdx still len? guest_ok clobbers edx. reload.
        push    rsi
        mov     rdi, rbx
        mov     esi, 12
        call    cpu_get_x
        mov     edx, eax
        pop     rsi
        mov     edi, r13d
        call    sys_write
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, 10
        call    cpu_set_x
        jmp     .adv
.wfault:
        mov     rdi, rbx
        mov     esi, 10
        mov     edx, -EFAULT
        call    cpu_set_x
        jmp     .adv

.read:
        mov     rdi, rbx
        mov     esi, 10
        call    cpu_get_x
        mov     r13d, eax
        mov     rdi, rbx
        mov     esi, 11
        call    cpu_get_x
        mov     r12d, eax
        mov     rdi, rbx
        mov     esi, 12
        call    cpu_get_x
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, r12d
        call    guest_ok
        test    eax, eax
        jz      .rfault
        mov     rdi, rbx
        mov     esi, r12d
        call    guest_ptr
        mov     rsi, rax
        push    rsi
        mov     rdi, rbx
        mov     esi, 12
        call    cpu_get_x
        mov     edx, eax
        pop     rsi
        mov     edi, r13d
        call    sys_read
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, 10
        call    cpu_set_x
        jmp     .adv
.rfault:
        mov     rdi, rbx
        mov     esi, 10
        mov     edx, -EFAULT
        call    cpu_set_x
        jmp     .adv

.cycle:
        mov     eax, [rbx + CPU_MCYCLE]
        mov     edx, eax
        mov     rdi, rbx
        mov     esi, 10
        call    cpu_set_x
        jmp     .adv

.sbrk:
        mov     rdi, rbx
        mov     esi, 10
        call    cpu_get_x               ; increment
        mov     ecx, [rbx + CPU_HEAP_BRK]
        add     eax, ecx
        ; clamp to stack_top - 4096
        mov     edx, [rbx + CPU_STACK_TOP]
        sub     edx, 4096
        cmp     eax, edx
        jbe     .sbrk_ok
        mov     eax, ecx                ; fail: return old, no bump — actually return -1
        mov     rdi, rbx
        mov     esi, 10
        mov     edx, -1
        call    cpu_set_x
        jmp     .adv
.sbrk_ok:
        mov     [rbx + CPU_HEAP_BRK], eax
        mov     edx, ecx                ; old break
        mov     rdi, rbx
        mov     esi, 10
        call    cpu_set_x
        jmp     .adv

.dump:
        mov     edi, STDERR_FILENO
        lea     rsi, [rel dump_hdr]
        call    io_cstr
        mov     edi, STDERR_FILENO
        call    io_nl
        xor     r13d, r13d
.dloop:
        cmp     r13d, 32
        jge     .adv
        mov     edi, STDERR_FILENO
        lea     rsi, [rel xname]
        call    io_cstr
        mov     edi, STDERR_FILENO
        mov     esi, r13d
        xor     edx, edx
        mov     ecx, 10
        call    io_dec
        mov     edi, STDERR_FILENO
        call    io_sp
        mov     rdi, rbx
        mov     esi, r13d
        call    cpu_get_x
        mov     edi, STDERR_FILENO
        mov     esi, eax
        call    io_hex32
        mov     edi, STDERR_FILENO
        call    io_nl
        inc     r13d
        jmp     .dloop

.adv:
        mov     rdi, rbx
        call    pc_advance
        pop     r13
        pop     r12
        pop     rbx
        ret
