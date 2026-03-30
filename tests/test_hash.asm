; tests/test_hash.asm
        bits 64
        default rel
%include "macros.inc"
%include "hash.inc"
        extern hash_init
        extern hash_put
        extern hash_get
        extern arena_alloc

        section .rodata
k1:     db "alpha"
k2:     db "beta"
k3:     db "gamma"

        section .bss
map:    resb HM_SIZE
val:    resq 1

        section .text
PROC test_hash
        push    rbx
        lea     rdi, [rel map]
        mov     esi, 64
        call    hash_init
        lea     rdi, [rel map]
        lea     rsi, [rel k1]
        mov     edx, 5
        mov     ecx, 42
        call    hash_put
        test    eax, eax
        jnz     .fail
        lea     rdi, [rel map]
        lea     rsi, [rel k2]
        mov     edx, 4
        mov     ecx, 99
        call    hash_put
        lea     rdi, [rel map]
        lea     rsi, [rel k1]
        mov     edx, 5
        lea     rcx, [rel val]
        call    hash_get
        test    eax, eax
        jnz     .fail
        cmp     qword [rel val], 42
        jne     .fail
        lea     rdi, [rel map]
        lea     rsi, [rel k3]
        mov     edx, 5
        lea     rcx, [rel val]
        call    hash_get
        cmp     eax, -1
        jne     .fail
        xor     eax, eax
        pop     rbx
        ret
.fail:
        mov     eax, 1
        pop     rbx
        ret
