; tests/test_cache.asm  — filled once the cache API exists; geometry sanity for now
        bits 64
        default rel
%include "macros.inc"
%include "cache.inc"
        section .text
PROC test_cache
        ; compile-time geometry checks executed as runtime compares
        mov     eax, L1I_WAYS
        cmp     eax, 2
        jne     .fail
        mov     eax, L1D_WAYS
        cmp     eax, 4
        jne     .fail
        mov     eax, LINE_SIZE
        cmp     eax, 64
        jne     .fail
        xor     eax, eax
        ret
.fail:
        mov     eax, 1
        ret
