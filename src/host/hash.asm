; src/host/hash.asm
; Open addressing, FNV-1a 64, linear probe. Keys are not copied: the caller
; owns the bytes (assembler source, interned labels). Growing reallocates
; the slot array from the arena and reinserts.

        bits 64
        default rel

%include "macros.inc"
%include "hash.inc"
%include "abi.inc"

        extern arena_alloc
        extern mem_set
        extern str_eq_n

        section .text

FNV_OFF: ; not a label for a value — use immediates
; FNV-1a 64 offset 14695981039346656037, prime 1099511628211

; uint64 fnv1a(const void *p, size_t n)
PROC fnv1a
        mov     rax, 14695981039346656037
        mov     rcx, 1099511628211
        test    rsi, rsi
        jz      .done
.loop:
        movzx   edx, byte [rdi]
        xor     rax, rdx
        imul    rax, rcx
        inc     rdi
        dec     rsi
        jnz     .loop
.done:
        ret

; void hash_init(map*, cap_pow2)
PROC hash_init
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12d, esi
        ; cap must be power of two
        mov     [rbx + HM_CAP], r12d
        xor     eax, eax
        mov     [rbx + HM_USED], eax
        mov     [rbx + HM_TOMBS], eax
        mov     edi, r12d
        imul    rdi, SLOT_SIZE
        mov     esi, 8
        call    arena_alloc
        mov     [rbx + HM_SLOTS], rax
        pop     r12
        pop     rbx
        ret

; internal: find slot index or empty. returns index in eax, found-live in edx
; rdi=map rsi=key edx=klen
find_slot:
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     rbx, rdi
        mov     r12, rsi
        mov     r13d, edx
        mov     rdi, r12
        mov     esi, r13d
        call    fnv1a
        mov     r14d, [rbx + HM_CAP]
        dec     r14d                    ; mask
        mov     r15d, eax
        and     r15d, r14d              ; start index
        mov     ecx, [rbx + HM_CAP]
        mov     r8d, -1                 ; first tomb
.probe:
        mov     rax, [rbx + HM_SLOTS]
        mov     edx, r15d
        imul    rdx, SLOT_SIZE
        add     rax, rdx                ; slot*
        mov     edx, [rax + SLOT_STATE]
        cmp     edx, HASH_EMPTY
        je      .empty
        cmp     edx, HASH_TOMB
        je      .tomb
        ; live: compare
        push    rcx
        push    rax
        mov     esi, [rax + SLOT_KLEN]
        mov     rdi, [rax + SLOT_KEY]
        mov     edx, r13d
        ; str_eq_n(a,alen,b,blen) rdi rsi rdx rcx — wait our sig is a,alen,b,blen
        ; rdi=a rsi=alen rdx=b rcx=blen
        mov     ecx, r13d
        mov     rdx, r12
        ; rdi already key in slot, esi klen
        call    str_eq_n
        pop     r9                      ; slot*
        pop     rcx
        test    eax, eax
        jnz     .hit
        jmp     .next
.tomb:
        cmp     r8d, -1
        jne     .next
        mov     r8d, r15d
        jmp     .next
.empty:
        cmp     r8d, -1
        je      .use_empty
        mov     eax, r8d
        xor     edx, edx
        jmp     .out
.use_empty:
        mov     eax, r15d
        xor     edx, edx
        jmp     .out
.hit:
        mov     eax, r15d
        mov     edx, 1
        jmp     .out
.next:
        inc     r15d
        and     r15d, r14d
        dec     ecx
        jnz     .probe
        ; table full of live+tomb
        mov     eax, r8d
        xor     edx, edx
.out:
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; int hash_put(map*, key, klen, val)  → 0 ok, -1 fail
PROC hash_put
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12, rsi
        mov     r13d, edx
        mov     r14, rcx
        ; grow if used+tombs > 3/4 cap
        mov     eax, [rbx + HM_USED]
        add     eax, [rbx + HM_TOMBS]
        shl     eax, 2
        mov     edx, [rbx + HM_CAP]
        imul    edx, 3
        cmp     eax, edx
        jle     .nogrow
        call    hash_grow
.nogrow:
        mov     rdi, rbx
        mov     rsi, r12
        mov     edx, r13d
        call    find_slot
        cmp     eax, -1
        je      .fail
        ; eax = index, edx = live hit
        mov     r8, [rbx + HM_SLOTS]
        mov     r9d, eax
        imul    r9, SLOT_SIZE
        add     r8, r9
        test    edx, edx
        jnz     .update
        cmp     dword [r8 + SLOT_STATE], HASH_TOMB
        jne     .fresh
        dec     dword [rbx + HM_TOMBS]
.fresh:
        mov     dword [r8 + SLOT_STATE], HASH_LIVE
        mov     [r8 + SLOT_KLEN], r13d
        mov     [r8 + SLOT_KEY], r12
        inc     dword [rbx + HM_USED]
.update:
        mov     [r8 + SLOT_VAL], r14
        xor     eax, eax
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.fail:
        mov     eax, -1
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; int hash_get(map*, key, klen, *val) → 0 hit, -1 miss
PROC hash_get
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12, rcx                ; out
        call    find_slot
        test    edx, edx
        jz      .miss
        mov     r8, [rbx + HM_SLOTS]
        imul    rax, SLOT_SIZE
        add     r8, rax
        mov     rax, [r8 + SLOT_VAL]
        mov     [r12], rax
        xor     eax, eax
        pop     r12
        pop     rbx
        ret
.miss:
        mov     eax, -1
        pop     r12
        pop     rbx
        ret

; void hash_grow(map*)  — double cap
hash_grow:
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rdi
        mov     r12d, [rbx + HM_CAP]
        mov     r13, [rbx + HM_SLOTS]
        mov     edi, r12d
        shl     edi, 1
        mov     esi, edi
        mov     rdi, rbx
        call    hash_init               ; new empty table, 2x
        ; reinsert lives from r13
        xor     r14d, r14d
.re:
        cmp     r14d, r12d
        jge     .done
        mov     rax, r13
        mov     edx, r14d
        imul    rdx, SLOT_SIZE
        add     rax, rdx
        cmp     dword [rax + SLOT_STATE], HASH_LIVE
        jne     .n
        mov     rdi, rbx
        mov     rsi, [rax + SLOT_KEY]
        mov     edx, [rax + SLOT_KLEN]
        mov     rcx, [rax + SLOT_VAL]
        call    hash_put
.n:
        inc     r14d
        jmp     .re
.done:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
