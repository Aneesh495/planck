; src/predict/predict.asm
; Tournament predictor: bimodal + gshare + chooser, BTB, RAS.

        bits 64
        default rel

%include "macros.inc"
%include "stats.inc"
%include "cpu.inc"

        extern arena_alloc

        section .text

PROC pred_create
        mov     edi, PRED_SIZE
        mov     esi, 64
        jmp     arena_alloc

; index from pc: bits [13:2]
pred_idx:
        mov     eax, edi
        shr     eax, 2
        and     eax, 4095
        ret

; int pred_direction(pred*, pc)  → 1 taken
PROC pred_direction
        push    rbx
        push    r12
        mov     rbx, rdi
        mov     r12d, esi
        mov     edi, r12d
        call    pred_idx
        mov     ecx, eax                ; bim idx
        movzx   eax, byte [rbx + PRED_BIM + rcx]
        ; gshare
        mov     edx, [rbx + PRED_GHR]
        mov     edi, r12d
        shr     edi, 2
        xor     edi, edx
        and     edi, 4095
        movzx   edx, byte [rbx + PRED_GS + rdi]
        movzx   esi, byte [rbx + PRED_CH + rcx]
        cmp     esi, 2
        jb      .bim
        ; use gshare
        cmp     edx, 2
        setae   al
        movzx   eax, al
        pop     r12
        pop     rbx
        ret
.bim:
        cmp     eax, 2
        setae   al
        movzx   eax, al
        pop     r12
        pop     rbx
        ret

sat_inc:
        cmp     edi, 3
        jae     .r
        inc     edi
.r:     mov     eax, edi
        ret

sat_dec:
        test    edi, edi
        jz      .r
        dec     edi
.r:     mov     eax, edi
        ret

; void pred_train(pred*, pc, taken)
PROC pred_train
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdi
        mov     r12d, esi
        mov     r13d, edx
        mov     edi, r12d
        call    pred_idx
        mov     ecx, eax
        movzx   edi, byte [rbx + PRED_BIM + rcx]
        test    r13d, r13d
        jz      .bd
        call    sat_inc
        jmp     .bs
.bd:    call    sat_dec
.bs:    mov     [rbx + PRED_BIM + rcx], al
        mov     edx, [rbx + PRED_GHR]
        mov     edi, r12d
        shr     edi, 2
        xor     edi, edx
        and     edi, 4095
        mov     r8d, edi
        movzx   edi, byte [rbx + PRED_GS + r8]
        test    r13d, r13d
        jz      .gd
        call    sat_inc
        jmp     .gs
.gd:    call    sat_dec
.gs:    mov     [rbx + PRED_GS + r8], al
        ; GHR
        mov     eax, [rbx + PRED_GHR]
        shl     eax, 1
        and     eax, 4095
        or      eax, r13d
        mov     [rbx + PRED_GHR], eax
        pop     r13
        pop     r12
        pop     rbx
        ret

; uint32 btb_look(pred*, pc, *kind)  0 miss
PROC btb_look
        mov     eax, esi
        shr     eax, 2
        and     eax, 127
        imul    eax, BTB_ENT_SIZE
        lea     r8, [rdi + PRED_BTB]
        add     r8, rax
        cmp     byte [r8 + BTB_VALID], 0
        je      .miss
        mov     eax, esi
        shr     eax, 2
        cmp     [r8 + BTB_TAG], eax
        jne     .miss
        mov     eax, [r8 + BTB_KIND]
        mov     [rdx], eax
        mov     eax, [r8 + BTB_TGT]
        ret
.miss:
        xor     eax, eax
        mov     dword [rdx], 0
        ret

; void btb_update(pred*, pc, tgt, kind)
PROC btb_update
        mov     eax, esi
        shr     eax, 2
        and     eax, 127
        imul    eax, BTB_ENT_SIZE
        lea     r8, [rdi + PRED_BTB]
        add     r8, rax
        mov     eax, esi
        shr     eax, 2
        mov     [r8 + BTB_TAG], eax
        mov     [r8 + BTB_TGT], edx
        mov     [r8 + BTB_KIND], ecx
        mov     byte [r8 + BTB_VALID], 1
        ret

; void ras_push(pred*, addr)
PROC ras_push
        mov     eax, [rdi + PRED_RAS_TOS]
        cmp     eax, RAS_CAP
        jb      .ok
        ; overflow: wrap
        xor     eax, eax
.ok:
        mov     [rdi + PRED_RAS + rax*4], esi
        inc     eax
        cmp     eax, RAS_CAP
        jbe     .s
        mov     eax, RAS_CAP
.s:
        mov     [rdi + PRED_RAS_TOS], eax
        ret

; uint32 ras_pop(pred*)
PROC ras_pop
        mov     eax, [rdi + PRED_RAS_TOS]
        test    eax, eax
        jz      .empty
        dec     eax
        mov     [rdi + PRED_RAS_TOS], eax
        mov     eax, [rdi + PRED_RAS + rax*4]
        ret
.empty:
        xor     eax, eax
        ret
