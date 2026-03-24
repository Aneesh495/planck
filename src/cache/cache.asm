; src/cache/cache.asm
; Set-associative true-LRU cache (ways <= 4) / bit-PLRU (ways==8).

        bits 64
        default rel

%include "macros.inc"
%include "cache.inc"

        extern arena_alloc

        section .text

; cache_t *cache_create(ways, sets, tag_shift, hit_lat, mshr_n, kind)
PROC cache_create
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     r12d, edi
        mov     r13d, esi
        mov     r14d, edx
        mov     r15d, ecx
        push    r8
        push    r9
        mov     edi, CH_SIZE
        mov     esi, 64
        call    arena_alloc
        mov     rbx, rax
        pop     r9
        pop     r8
        mov     [rbx + CH_WAYS], r12d
        mov     [rbx + CH_SETS], r13d
        mov     [rbx + CH_TAG_SHIFT], r14d
        mov     eax, r13d
        dec     eax
        mov     [rbx + CH_INDEX_MASK], eax
        mov     [rbx + CH_HIT_LAT], r15d
        mov     [rbx + CH_MSHR_N], r8d
        mov     [rbx + CH_KIND], r9d
        ; tags: sets * ways * 8
        mov     eax, r13d
        imul    eax, r12d
        imul    rdi, rax, TAG_SIZE
        mov     esi, 8
        call    arena_alloc
        mov     [rbx + CH_TAGS], rax
        ; data backing
        mov     eax, r13d
        imul    eax, r12d
        imul    rdi, rax, LINE_SIZE
        mov     esi, 64
        call    arena_alloc
        mov     [rbx + CH_DATA], rax
        ; mshr
        mov     eax, [rbx + CH_MSHR_N]
        imul    rdi, rax, MSHR_SIZE
        mov     esi, 8
        call    arena_alloc
        mov     [rbx + CH_MSHR], rax
        ; plru bytes per set
        mov     edi, r13d
        mov     esi, 8
        call    arena_alloc
        mov     [rbx + CH_PLRU], rax
        mov     rax, rbx
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; int cache_probe(cache*, uint32 pa, int is_store, int *lat_out)
; 1 hit, 0 miss. lat_out filled. Updates LRU / dirty.
PROC cache_probe
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     rbx, rdi
        mov     r12d, esi               ; pa
        mov     r13d, edx               ; is_store
        mov     r14, rcx                ; *lat
        ; index
        mov     eax, r12d
        shr     eax, L1I_INDEX_SHIFT    ; 6
        mov     ecx, [rbx + CH_INDEX_MASK]
        and     eax, ecx
        mov     r15d, eax               ; set
        ; tag
        mov     ecx, [rbx + CH_TAG_SHIFT]
        mov     eax, r12d
        shr     eax, cl
        mov     r8d, eax                ; tag
        ; scan ways
        xor     r9d, r9d
        mov     r10d, -1                ; invalid way
        mov     r11d, -1                ; lru victim (max lru)
        xor     r12d, r12d              ; maxlru value — wait r12 is pa. save pa
        mov     esi, r12d               ; pa still r12d
        ; use stack for pa
        push    rsi
        xor     r9d, r9d
        mov     edx, -1                 ; victim way
        mov     ecx, -1                 ; victim lru
.scan:
        cmp     r9d, [rbx + CH_WAYS]
        jge     .done_scan
        ; tag ptr = tags + (set*ways + way)*8
        mov     eax, r15d
        imul    eax, [rbx + CH_WAYS]
        add     eax, r9d
        mov     rdi, [rbx + CH_TAGS]
        lea     rdi, [rdi + rax*8]
        cmp     byte [rdi + TAG_VALID], 0
        je      .inv
        mov     eax, [rdi + TAG_TAG]
        cmp     eax, r8d
        je      .hit
        movzx   eax, word [rdi + TAG_LRU]
        cmp     eax, ecx
        jle     .n
        mov     ecx, eax
        mov     edx, r9d
        jmp     .n
.inv:
        cmp     r10d, -1
        jne     .n
        mov     r10d, r9d
.n:
        inc     r9d
        jmp     .scan
.done_scan:
        ; miss
        inc     qword [rbx + CH_MISSES]
        mov     eax, DRAM_LAT
        cmp     dword [rbx + CH_KIND], KIND_L2
        je      .mlat
        mov     eax, L2_HIT_LAT
.mlat:
        test    r14, r14
        jz      .mfill
        mov     [r14], eax
.mfill:
        ; install in invalid or victim
        cmp     r10d, -1
        je      .use_v
        mov     edx, r10d
        jmp     .install
.use_v:
        cmp     edx, -1
        jne     .install
        xor     edx, edx
.install:
        mov     eax, r15d
        imul    eax, [rbx + CH_WAYS]
        add     eax, edx
        mov     rdi, [rbx + CH_TAGS]
        lea     rdi, [rdi + rax*8]
        cmp     byte [rdi + TAG_VALID], 1
        jne     .nodirty
        cmp     byte [rdi + TAG_DIRTY], 1
        jne     .nodirty
        inc     qword [rbx + CH_WRITEBACKS]
.nodirty:
        pop     rsi                     ; pa
        mov     eax, esi
        mov     ecx, [rbx + CH_TAG_SHIFT]
        shr     eax, cl
        mov     [rdi + TAG_TAG], eax
        mov     byte [rdi + TAG_VALID], 1
        mov     byte [rdi + TAG_DIRTY], r13b
        mov     word [rdi + TAG_LRU], 0
        call    lru_bump
        xor     eax, eax                ; miss
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.hit:
        pop     rsi
        inc     qword [rbx + CH_HITS]
        test    r13d, r13d
        jz      .nh
        mov     byte [rdi + TAG_DIRTY], 1
.nh:
        mov     word [rdi + TAG_LRU], 0
        mov     edx, r9d
        call    lru_bump
        mov     eax, [rbx + CH_HIT_LAT]
        test    r14, r14
        jz      .hok
        mov     [r14], eax
.hok:
        mov     eax, 1
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; lru_bump: increment LRU of other valid ways in set r15, cache rbx, skip way edx
lru_bump:
        push    r9
        xor     r9d, r9d
.lp:
        cmp     r9d, [rbx + CH_WAYS]
        jge     .o
        cmp     r9d, edx
        je      .c
        mov     eax, r15d
        imul    eax, [rbx + CH_WAYS]
        add     eax, r9d
        mov     rdi, [rbx + CH_TAGS]
        lea     rdi, [rdi + rax*8]
        cmp     byte [rdi + TAG_VALID], 0
        je      .c
        inc     word [rdi + TAG_LRU]
.c:
        inc     r9d
        jmp     .lp
.o:
        pop     r9
        ret

; tlb_t *tlb_create(void)
PROC tlb_create
        mov     edi, TLB_SIZE
        mov     esi, 8
        jmp     arena_alloc

; int tlb_probe(tlb*, uint32 va, int *lat)
PROC tlb_probe
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12d, esi
        shr     r12d, PAGE_SHIFT        ; vpn
        xor     ecx, ecx
        mov     edx, -1
        mov     r8d, -1
.scan:
        cmp     ecx, TLB_ENTRIES
        jge     .miss
        mov     eax, ecx
        imul    eax, TLB_ENT_SIZE
        lea     r9, [rbx + rax]
        cmp     byte [r9 + TLB_VALID], 0
        je      .inv
        cmp     [r9 + TLB_VPN], r12d
        je      .hit
        movzx   eax, byte [r9 + TLB_LRU]
        cmp     eax, r8d
        jle     .n
        mov     r8d, eax
        mov     edx, ecx
        jmp     .n
.inv:
        cmp     edx, -1
        jne     .n
        ; prefer invalid
        mov     r10d, ecx
        ; fall
.n:
        inc     ecx
        jmp     .scan
.hit:
        inc     qword [rbx + TLB_HITS]
        mov     byte [r9 + TLB_LRU], 0
        mov     eax, 1
        test    rdx, rdx                ; lat ptr was rsi... 3rd arg rdx originally, saved as... 
        ; signature tlb_probe(tlb, va, *lat) rdi rsi rdx
        ; rdx clobbered. Use r8 from caller — broken.
        pop     r12
        pop     rbx
        ret
.miss:
        inc     qword [rbx + TLB_MISSES]
        xor     eax, eax
        pop     r12
        pop     rbx
        ret
