; src/host/io.asm
; Integer and string writers. No printf, no buffering beyond a 64-byte local.

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"

        extern sys_write
        extern str_len

        section .text

; void io_write(int fd, const void *buf, size_t n)
PROC io_write
        jmp     sys_write

; void io_cstr(int fd, const char *s)
PROC io_cstr
        push    rdi
        push    rsi
        mov     rdi, rsi
        call    str_len
        mov     rdx, rax
        pop     rsi
        pop     rdi
        jmp     sys_write

; void io_chr(int fd, int c)
PROC io_chr
        push    rsi                     ; byte lives in sil
        mov     byte [rsp], sil
        mov     rsi, rsp
        mov     edx, 1
        call    sys_write
        pop     rax
        ret

; void io_nl(int fd)
PROC io_nl
        mov     esi, 10
        jmp     io_chr

; void io_sp(int fd)
PROC io_sp
        mov     esi, 32
        jmp     io_chr

; void io_u64(int fd, uint64 val, int width, int base)
; width is minimum digits (zero-padded if > 0). base 10 or 16.
PROC io_u64
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        sub     rsp, 80
        mov     r12d, edi               ; fd
        mov     r13, rsi                ; val
        mov     r14d, edx               ; width
        mov     r15d, ecx               ; base
        test    r15d, r15d
        jnz     .base_ok
        mov     r15d, 10
.base_ok:
        lea     rbx, [rsp+64]           ; end of digit buf
        mov     byte [rbx], 0
        mov     rax, r13
        test    rax, rax
        jnz     .conv
        dec     rbx
        mov     byte [rbx], '0'
        jmp     .pad
.conv:
        xor     edx, edx
        div     r15
        ; remainder rdx
        cmp     edx, 10
        jb      .digit
        add     edx, 'a' - 10
        jmp     .store
.digit:
        add     edx, '0'
.store:
        dec     rbx
        mov     [rbx], dl
        mov     r13, rax
        test    rax, rax
        jnz     .conv
.pad:
        ; rbx → digits, length = end-rbx
        lea     rax, [rsp+64]
        sub     rax, rbx
        mov     ecx, r14d
        sub     ecx, eax
        jle     .emit
        ; write leading zeros
.zloop:
        push    rcx
        push    rax
        mov     edi, r12d
        mov     esi, '0'
        call    io_chr
        pop     rax
        pop     rcx
        dec     ecx
        jnz     .zloop
.emit:
        lea     rdx, [rsp+64]
        sub     rdx, rbx                ; len
        mov     edi, r12d
        mov     rsi, rbx
        call    sys_write
        add     rsp, 80
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; void io_i64(int fd, int64 val, int width, int base)
PROC io_i64
        test    rsi, rsi
        jns     io_u64
        push    rdi
        push    rsi
        push    rdx
        push    rcx
        mov     esi, '-'
        call    io_chr
        pop     rcx
        pop     rdx
        pop     rsi
        pop     rdi
        neg     rsi
        jmp     io_u64

; void io_hex32(int fd, uint32 val)  — prints 0x then 8 digits
PROC io_hex32
        push    rsi
        push    rdi
        mov     esi, '0'
        call    io_chr
        pop     rdi
        push    rdi
        mov     esi, 'x'
        call    io_chr
        pop     rdi
        pop     rsi
        mov     edx, 8
        mov     ecx, 16
        mov     esi, esi                ; zero-extend already in rsi from caller
        mov     esi, esi
        ; rsi still holds original val? we popped it into... wait we popped rsi at start after push
        ; Fix: val is in esi from entry. We pushed rsi then used sil for chars.
        ; After pop rsi, rsi is restored. Good.
        jmp     io_u64

; void io_hex64(int fd, uint64 val)
PROC io_hex64
        push    rsi
        push    rdi
        mov     esi, '0'
        call    io_chr
        pop     rdi
        push    rdi
        mov     esi, 'x'
        call    io_chr
        pop     rdi
        pop     rsi
        mov     edx, 16
        mov     ecx, 16
        jmp     io_u64

; void io_dec(int fd, int64 val)
PROC io_dec
        xor     edx, edx
        mov     ecx, 10
        jmp     io_i64

; void io_udec(int fd, uint64 val)
PROC io_udec
        xor     edx, edx
        mov     ecx, 10
        jmp     io_u64

; void io_spaces(int fd, int n)
PROC io_spaces
        test    esi, esi
        jle     .done
.loop:
        push    rdi
        push    rsi
        mov     esi, 32
        call    io_chr
        pop     rsi
        pop     rdi
        dec     esi
        jnz     .loop
.done:
        ret
