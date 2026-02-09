; src/host/string.asm
; Freestanding string/memory primitives. No libc, no SIMD except where a
; simple word fill is obviously better than a byte loop.

        bits 64
        default rel

%include "macros.inc"

        section .text

; size_t str_len(const char *s)
PROC str_len
        mov     rax, rdi
.loop:
        cmp     byte [rdi], 0
        je      .done
        inc     rdi
        jmp     .loop
.done:
        sub     rdi, rax
        mov     rax, rdi
        ret

; int str_cmp(const char *a, const char *b)
PROC str_cmp
.loop:
        movzx   eax, byte [rdi]
        movzx   ecx, byte [rsi]
        cmp     eax, ecx
        jne     .diff
        test    eax, eax
        jz      .eq
        inc     rdi
        inc     rsi
        jmp     .loop
.diff:
        sub     eax, ecx
        ret
.eq:
        xor     eax, eax
        ret

; int str_ncmp(const char *a, const char *b, size_t n)
PROC str_ncmp
        test    rdx, rdx
        jz      .eq
.loop:
        movzx   eax, byte [rdi]
        movzx   ecx, byte [rsi]
        cmp     eax, ecx
        jne     .diff
        test    eax, eax
        jz      .eq
        inc     rdi
        inc     rsi
        dec     rdx
        jnz     .loop
.eq:
        xor     eax, eax
        ret
.diff:
        sub     eax, ecx
        ret

; char *str_chr(const char *s, int c)
PROC str_chr
.loop:
        movzx   eax, byte [rdi]
        cmp     eax, esi
        je      .hit
        test    eax, eax
        jz      .miss
        inc     rdi
        jmp     .loop
.hit:
        mov     rax, rdi
        ret
.miss:
        xor     eax, eax
        ret

; void *mem_cpy(void *dst, const void *src, size_t n)
PROC mem_cpy
        mov     rax, rdi
        test    rdx, rdx
        jz      .done
        ; byte copy: images are small, correctness first
.loop:
        mov     cl, [rsi]
        mov     [rdi], cl
        inc     rsi
        inc     rdi
        dec     rdx
        jnz     .loop
.done:
        ret

; void *mem_move(void *dst, const void *src, size_t n)
PROC mem_move
        mov     rax, rdi
        test    rdx, rdx
        jz      .done
        cmp     rdi, rsi
        je      .done
        jb      .fwd
        ; dst > src: copy backwards
        lea     rdi, [rdi + rdx - 1]
        lea     rsi, [rsi + rdx - 1]
.bwd:
        mov     cl, [rsi]
        mov     [rdi], cl
        dec     rsi
        dec     rdi
        dec     rdx
        jnz     .bwd
        ret
.fwd:
        mov     cl, [rsi]
        mov     [rdi], cl
        inc     rsi
        inc     rdi
        dec     rdx
        jnz     .fwd
.done:
        ret

; void *mem_set(void *dst, int c, size_t n)
PROC mem_set
        mov     rax, rdi
        test    rdx, rdx
        jz      .done
.loop:
        mov     [rdi], sil
        inc     rdi
        dec     rdx
        jnz     .loop
.done:
        ret

; int mem_cmp(const void *a, const void *b, size_t n)
PROC mem_cmp
        test    rdx, rdx
        jz      .eq
.loop:
        movzx   eax, byte [rdi]
        movzx   ecx, byte [rsi]
        cmp     eax, ecx
        jne     .diff
        inc     rdi
        inc     rsi
        dec     rdx
        jnz     .loop
.eq:
        xor     eax, eax
        ret
.diff:
        sub     eax, ecx
        ret

; int is_space(int c)  — space, tab, CR, VT, FF (not newline: lexer wants NL tokens)
PROC is_space
        cmp     edi, 32
        je      .yes
        cmp     edi, 9
        je      .yes
        cmp     edi, 13
        je      .yes
        cmp     edi, 11
        je      .yes
        cmp     edi, 12
        je      .yes
        xor     eax, eax
        ret
.yes:
        mov     eax, 1
        ret

; int is_digit(int c)
PROC is_digit
        sub     edi, '0'
        cmp     edi, 10
        jae     .no
        mov     eax, 1
        ret
.no:
        xor     eax, eax
        ret

; int is_xdigit(int c)
PROC is_xdigit
        mov     eax, edi
        sub     eax, '0'
        cmp     eax, 10
        jb      .yes
        mov     eax, edi
        or      eax, 32
        sub     eax, 'a'
        cmp     eax, 6
        jb      .yes
        xor     eax, eax
        ret
.yes:
        mov     eax, 1
        ret

; int is_alpha(int c)
PROC is_alpha
        mov     eax, edi
        or      eax, 32
        sub     eax, 'a'
        cmp     eax, 26
        jae     .no
        mov     eax, 1
        ret
.no:
        xor     eax, eax
        ret

; int is_ident_start(int c)  letter, _, ., $
PROC is_ident_start
        cmp     edi, '_'
        je      .yes
        cmp     edi, '.'
        je      .yes
        cmp     edi, '$'
        je      .yes
        jmp     is_alpha
.yes:
        mov     eax, 1
        ret

; int is_ident_cont(int c)
PROC is_ident_cont
        push    rdi
        call    is_ident_start
        pop     rdi
        test    eax, eax
        jnz     .yes
        jmp     is_digit
.yes:
        ret

; int is_alnum(int c)
PROC is_alnum
        push    rdi
        call    is_alpha
        pop     rdi
        test    eax, eax
        jnz     .yes
        jmp     is_digit
.yes:
        ret

; int hex_val(int c)  → 0..15 or -1
PROC hex_val
        mov     eax, edi
        sub     eax, '0'
        cmp     eax, 10
        jb      .ok
        mov     eax, edi
        or      eax, 32
        sub     eax, 'a'
        cmp     eax, 6
        jae     .bad
        add     eax, 10
        ret
.bad:
        mov     eax, -1
.ok:
        ret

; int parse_int(const char *s, int len, int *out)
; accepts optional '-', 0x, 0b, decimal. returns 0 ok, -1 bad.
PROC parse_int
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     r12, rdi                ; s
        mov     r13d, esi               ; len
        mov     r14, rdx                ; out
        xor     ebx, ebx                ; neg
        test    r13d, r13d
        jz      .bad
        cmp     byte [r12], '-'
        jne     .sign_done
        mov     ebx, 1
        inc     r12
        dec     r13d
        jz      .bad
.sign_done:
        ; 0x / 0b prefix
        cmp     r13d, 3
        jl      .dec
        cmp     byte [r12], '0'
        jne     .dec
        movzx   eax, byte [r12+1]
        or      eax, 32
        cmp     eax, 'x'
        je      .hex
        cmp     eax, 'b'
        je      .bin
.dec:
        xor     eax, eax
        xor     ecx, ecx
.dec_loop:
        cmp     ecx, r13d
        jge     .apply
        movzx   edx, byte [r12+rcx]
        sub     edx, '0'
        cmp     edx, 10
        jae     .bad
        imul    eax, eax, 10
        add     eax, edx
        inc     ecx
        jmp     .dec_loop
.hex:
        add     r12, 2
        sub     r13d, 2
        xor     eax, eax
        xor     ecx, ecx
.hex_loop:
        cmp     ecx, r13d
        jge     .apply
        movzx   edi, byte [r12+rcx]
        push    rax
        push    rcx
        call    hex_val
        mov     edx, eax
        pop     rcx
        pop     rax
        cmp     edx, 0
        js      .bad
        shl     eax, 4
        add     eax, edx
        inc     ecx
        jmp     .hex_loop
.bin:
        add     r12, 2
        sub     r13d, 2
        xor     eax, eax
        xor     ecx, ecx
.bin_loop:
        cmp     ecx, r13d
        jge     .apply
        movzx   edx, byte [r12+rcx]
        sub     edx, '0'
        cmp     edx, 2
        jae     .bad
        shl     eax, 1
        add     eax, edx
        inc     ecx
        jmp     .bin_loop
.apply:
        test    ebx, ebx
        jz      .store
        neg     eax
.store:
        mov     [r14], eax
        xor     eax, eax
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.bad:
        mov     eax, -1
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; int str_eq(const char *a, const char *b)
PROC str_eq
        call    str_cmp
        test    eax, eax
        setz    al
        movzx   eax, al
        ret

; int str_eq_n(const char *a, int alen, const char *b, int blen)
; rdi=a rsi=alen rdx=b rcx=blen
PROC str_eq_n
        cmp     esi, ecx
        jne     .no
        mov     ecx, esi
        test    ecx, ecx
        jz      .yes
.loop:
        mov     al, [rdi]
        cmp     al, [rdx]
        jne     .no
        inc     rdi
        inc     rdx
        dec     ecx
        jnz     .loop
.yes:
        mov     eax, 1
        ret
.no:
        xor     eax, eax
        ret
