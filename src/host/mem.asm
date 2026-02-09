; src/host/mem.asm
; Bump arena over one mmap, plus guest-physical translation.

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"
%include "abi.inc"
%include "arena.inc"
%include "cpu.inc"

        extern sys_mmap
        extern sys_munmap
        extern host_die
        extern mem_set

        section .data
        global g_arena
g_arena:        dq 0

        section .rodata
err_mmap:       db "mmap failed",0
err_oom:        db "arena: out of memory",0
err_align:      db "arena: bad align",0
err_gpf:        db "guest address fault",0

        section .text

; void *arena_create(size_t bytes)  — maps, stores in g_arena, returns arena*
PROC arena_create
        push    rbx
        mov     rbx, rdi                ; size
        xor     edi, edi                ; addr
        mov     rsi, rbx
        mov     edx, PROT_READ | PROT_WRITE
        mov     ecx, MAP_PRIVATE | MAP_ANONYMOUS
        mov     r8d, -1
        xor     r9d, r9d
        call    sys_mmap
        cmp     rax, -4096
        ja      .fail                   ; Linux mmap error: -errno in rax, > -4096
        ; Layout: arena header at base, bump starts after AR_SIZE aligned 64
        mov     rdi, rax
        mov     [g_arena], rax
        mov     [rax + AR_BASE], rax
        lea     rcx, [rax + 64]
        mov     [rax + AR_CUR], rcx
        add     rcx, rbx
        ; wait, AR_END should be base+bytes, CUR = base+64
        mov     rdx, rax
        add     rdx, rbx
        mov     [rax + AR_END], rdx
        pop     rbx
        ret
.fail:
        lea     rdi, [rel err_mmap]
        call    host_die
        pop     rbx
        ret

; void arena_destroy(void)
PROC arena_destroy
        mov     rax, [g_arena]
        test    rax, rax
        jz      .done
        mov     rdi, [rax + AR_BASE]
        mov     rsi, [rax + AR_END]
        sub     rsi, rdi
        call    sys_munmap
        mov     qword [g_arena], 0
.done:
        ret

; void arena_reset(void)  — keep mapping, rewind bump
PROC arena_reset
        mov     rax, [g_arena]
        test    rax, rax
        jz      .done
        lea     rcx, [rax + 64]
        mov     [rax + AR_CUR], rcx
.done:
        ret

; void *arena_alloc(size_t bytes, size_t align)
PROC arena_alloc
        push    rbx
        mov     rax, [g_arena]
        test    rax, rax
        jz      .oom
        mov     rbx, rax
        ; align must be power of two
        mov     rcx, rsi
        test    rcx, rcx
        jz      .bad_al
        lea     rdx, [rcx - 1]
        test    rcx, rdx
        jnz     .bad_al
        mov     rax, [rbx + AR_CUR]
        add     rax, rdx
        not     rdx
        and     rax, rdx                ; aligned cur
        mov     rcx, rax
        add     rcx, rdi                ; new cur
        cmp     rcx, [rbx + AR_END]
        ja      .oom
        mov     [rbx + AR_CUR], rcx
        ; zero the allocation so structures start clean
        push    rax
        mov     rdx, rdi
        xor     esi, esi
        mov     rdi, rax
        call    mem_set
        pop     rax
        pop     rbx
        ret
.bad_al:
        lea     rdi, [rel err_align]
        call    host_die
.oom:
        lea     rdi, [rel err_oom]
        call    host_die
        pop     rbx
        ret

; int guest_ok(cpu, guest_addr, len)  — 1 if entirely in RAM
PROC guest_ok
        ; rdi=cpu rsi=gaddr edx=len
        mov     eax, esi
        mov     ecx, [rdi + CPU_MEM_SIZE]
        add     ecx, GUEST_RESET
        cmp     eax, GUEST_RESET
        jb      .no
        mov     r8d, eax
        add     r8d, edx
        jc      .no                     ; overflow
        cmp     r8d, ecx
        ja      .no
        mov     eax, 1
        ret
.no:
        xor     eax, eax
        ret

; void *guest_ptr(cpu, guest_addr)  — no check
PROC guest_ptr
        mov     eax, esi
        sub     eax, GUEST_RESET
        add     rax, [rdi + CPU_MEM_BASE]
        ret

; int guest_load_u8(cpu, addr, *out)
PROC guest_load_u8
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rdx
        mov     edx, 1
        call    guest_ok
        test    eax, eax
        jz      .fault
        mov     rdi, rbx
        ; rsi still addr
        call    guest_ptr
        movzx   eax, byte [rax]
        mov     [r12], eax
        xor     eax, eax
        pop     r12
        pop     rbx
        ret
.fault:
        mov     eax, -1
        pop     r12
        pop     rbx
        ret

PROC guest_load_u16
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rdx
        mov     edx, 2
        call    guest_ok
        test    eax, eax
        jz      .fault
        mov     rdi, rbx
        call    guest_ptr
        movzx   eax, word [rax]
        mov     [r12], eax
        xor     eax, eax
        pop     r12
        pop     rbx
        ret
.fault:
        mov     eax, -1
        pop     r12
        pop     rbx
        ret

PROC guest_load_u32
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rdx
        mov     edx, 4
        call    guest_ok
        test    eax, eax
        jz      .fault
        mov     rdi, rbx
        call    guest_ptr
        mov     eax, [rax]
        mov     [r12], eax
        xor     eax, eax
        pop     r12
        pop     rbx
        ret
.fault:
        mov     eax, -1
        pop     r12
        pop     rbx
        ret

PROC guest_store_u8
        push    rbx
        mov     rbx, rdi
        push    rdx
        mov     edx, 1
        call    guest_ok
        pop     rdx
        test    eax, eax
        jz      .fault
        mov     rdi, rbx
        call    guest_ptr
        mov     [rax], dl
        xor     eax, eax
        pop     rbx
        ret
.fault:
        mov     eax, -1
        pop     rbx
        ret

PROC guest_store_u16
        push    rbx
        mov     rbx, rdi
        push    rdx
        mov     edx, 2
        call    guest_ok
        pop     rdx
        test    eax, eax
        jz      .fault
        mov     rdi, rbx
        call    guest_ptr
        mov     [rax], dx
        xor     eax, eax
        pop     rbx
        ret
.fault:
        mov     eax, -1
        pop     rbx
        ret

PROC guest_store_u32
        push    rbx
        mov     rbx, rdi
        push    rdx
        mov     edx, 4
        call    guest_ok
        pop     rdx
        test    eax, eax
        jz      .fault
        mov     rdi, rbx
        call    guest_ptr
        mov     [rax], edx
        xor     eax, eax
        pop     rbx
        ret
.fault:
        mov     eax, -1
        pop     rbx
        ret

; signed loads: load unsigned then sext
PROC guest_load_i8
        push    rdx
        call    guest_load_u8
        pop     rdx
        test    eax, eax
        jnz     .f
        mov     eax, [rdx]
        movsx   eax, al
        mov     [rdx], eax
        xor     eax, eax
.f:
        ret

PROC guest_load_i16
        push    rdx
        call    guest_load_u16
        pop     rdx
        test    eax, eax
        jnz     .f
        mov     eax, [rdx]
        movsx   eax, ax
        mov     [rdx], eax
        xor     eax, eax
.f:
        ret
