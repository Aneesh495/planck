; src/host/file.asm
; Read an entire file into an arena buffer.

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"
%include "abi.inc"

        extern sys_openat
        extern sys_close
        extern sys_lseek
        extern sys_read
        extern arena_alloc
        extern host_die

        section .rodata
err_open:       db "cannot open file",0
err_size:       db "cannot stat file",0
err_big:        db "file too large",0
err_read:       db "short read",0

        section .text

; int host_read_file(const char *path, void **ptr, uint64 *len)
; 0 ok, dies on failure (simpler CLI). Returns 0.
PROC host_read_file
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     r12, rdi                ; path
        mov     r13, rsi                ; **ptr
        mov     r14, rdx                ; *len
        mov     edi, AT_FDCWD
        mov     rsi, r12
        mov     edx, O_RDONLY
        xor     ecx, ecx
        call    sys_openat
        cmp     rax, -4096
        ja      .eopen
        mov     rbx, rax                ; fd
        mov     rdi, rbx
        xor     esi, esi
        mov     edx, SEEK_END
        call    sys_lseek
        cmp     rax, -4096
        ja      .esize
        mov     r15, rax                ; size
        cmp     r15, MAX_SOURCE_BYTES
        ja      .ebig
        mov     rdi, rbx
        xor     esi, esi
        mov     edx, SEEK_SET
        call    sys_lseek
        ; alloc size+1 for NUL
        mov     rdi, r15
        inc     rdi
        mov     esi, 8
        call    arena_alloc
        mov     r12, rax                ; buf (reuse r12)
        test    r15, r15
        jz      .empty
        mov     rdi, rbx
        mov     rsi, r12
        mov     rdx, r15
        call    sys_read
        cmp     rax, r15
        jne     .eread
.empty:
        mov     byte [r12 + r15], 0
        mov     [r13], r12
        mov     [r14], r15
        mov     rdi, rbx
        call    sys_close
        xor     eax, eax
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.eopen:
        lea     rdi, [rel err_open]
        call    host_die
.esize:
        lea     rdi, [rel err_size]
        call    host_die
.ebig:
        lea     rdi, [rel err_big]
        call    host_die
.eread:
        lea     rdi, [rel err_read]
        call    host_die
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; int host_write_file(const char *path, const void *buf, uint64 len)
PROC host_write_file
        push    rbx
        push    r12
        push    r13
        mov     r12, rsi
        mov     r13, rdx
        mov     edi, AT_FDCWD
        ; rdi was path — need path in rsi for openat. redo:
        ; wait we clobbered. Use stack.
        ; Actually: on entry rdi=path rsi=buf rdx=len. We saved buf,len. path still rdi.
        mov     rsi, rdi
        mov     edi, AT_FDCWD
        mov     edx, O_WRONLY | O_CREAT | O_TRUNC
        mov     ecx, 0644o
        call    sys_openat
        cmp     rax, -4096
        ja      .fail
        mov     rbx, rax
        mov     rdi, rbx
        mov     rsi, r12
        mov     rdx, r13
        call    sys_write
        mov     rdi, rbx
        call    sys_close
        xor     eax, eax
        pop     r13
        pop     r12
        pop     rbx
        ret
.fail:
        mov     eax, -1
        pop     r13
        pop     r12
        pop     rbx
        ret
