; src/ooo/fu.asm
; Combinational evaluation of ALU/BR/M for the OoO execute stage.
; Memory ops are not evaluated here.

        bits 64
        default rel

%include "macros.inc"
%include "rv32.inc"

        section .text

; int fu_eval(id, s1, s2, imm, pc, *val, *npc)
; returns 1 if branch/jump (npc valid), 0 otherwise. *val is rd result.
PROC fu_eval
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     ebx, edi                ; id
        mov     r12d, esi               ; s1
        mov     r13d, edx               ; s2
        mov     r14d, ecx               ; imm
        mov     r15d, r8d               ; pc  — 5th is r8
        ; r9 = *val, stack 6th *npc on stack? SysV r9 is 6th = *val, [rsp+...] 7th
        ; args: rdi id, rsi s1, rdx s2, rcx imm, r8 pc, r9 *val, stack *npc
        mov     rax, r9                 ; *val
        push    rax
        ; npc pointer: 8 pushes? we pushed 5 regs then *val. original 7th at rsp+48+?
        ; After 5 pushes + 1 push = 48 bytes, return addr + 0 from caller's arg7
        ; On entry 7th arg at [rsp+8] (ret). After 6 pushes [rsp+56]
        mov     r10, [rsp + 56]         ; maybe wrong. Use a different ABI: pack npc in r11 via global? 
        ; Simpler signature: fu_eval writes [r9] val and returns npc in edx, taken in eax.
        pop     rax
        ; *val in r9 still
        xor     edx, edx                ; npc default pc+4
        mov     eax, r15d
        add     eax, 4
        mov     edx, eax
        xor     eax, eax                ; not a redirect

        cmp     ebx, ID_LUI
        je      .lui
        cmp     ebx, ID_AUIPC
        je      .auipc
        cmp     ebx, ID_ADDI
        je      .addi
        cmp     ebx, ID_ADD
        je      .add
        cmp     ebx, ID_SUB
        je      .sub
        cmp     ebx, ID_AND
        je      .and
        cmp     ebx, ID_OR
        je      .or
        cmp     ebx, ID_XOR
        je      .xor
        cmp     ebx, ID_ANDI
        je      .andi
        cmp     ebx, ID_ORI
        je      .ori
        cmp     ebx, ID_XORI
        je      .xori
        cmp     ebx, ID_SLL
        je      .sll
        cmp     ebx, ID_SRL
        je      .srl
        cmp     ebx, ID_SRA
        je      .sra
        cmp     ebx, ID_SLLI
        je      .slli
        cmp     ebx, ID_SRLI
        je      .srli
        cmp     ebx, ID_SRAI
        je      .srai
        cmp     ebx, ID_SLT
        je      .slt
        cmp     ebx, ID_SLTU
        je      .sltu
        cmp     ebx, ID_SLTI
        je      .slti
        cmp     ebx, ID_SLTIU
        je      .sltiu
        cmp     ebx, ID_BEQ
        je      .beq
        cmp     ebx, ID_BNE
        je      .bne
        cmp     ebx, ID_BLT
        je      .blt
        cmp     ebx, ID_BGE
        je      .bge
        cmp     ebx, ID_BLTU
        je      .bltu
        cmp     ebx, ID_BGEU
        je      .bgeu
        cmp     ebx, ID_JAL
        je      .jal
        cmp     ebx, ID_JALR
        je      .jalr
        cmp     ebx, ID_MUL
        je      .mul
        cmp     ebx, ID_DIV
        je      .div
        cmp     ebx, ID_DIVU
        je      .divu
        cmp     ebx, ID_REM
        je      .rem
        cmp     ebx, ID_REMU
        je      .remu
        cmp     ebx, ID_MULH
        je      .mulh
        cmp     ebx, ID_MULHU
        je      .mulhu
        cmp     ebx, ID_MULHSU
        je      .mulhsu
        jmp     .done

.lui:
        mov     eax, r14d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.auipc:
        mov     eax, r15d
        add     eax, r14d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.addi:
        mov     eax, r12d
        add     eax, r14d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.add:
        mov     eax, r12d
        add     eax, r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.sub:
        mov     eax, r12d
        sub     eax, r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.and:
        mov     eax, r12d
        and     eax, r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.or:
        mov     eax, r12d
        or      eax, r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.xor:
        mov     eax, r12d
        xor     eax, r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.andi:
        mov     eax, r12d
        and     eax, r14d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.ori:
        mov     eax, r12d
        or      eax, r14d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.xori:
        mov     eax, r12d
        xor     eax, r14d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.sll:
        mov     eax, r12d
        mov     ecx, r13d
        and     ecx, 31
        shl     eax, cl
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.srl:
        mov     eax, r12d
        mov     ecx, r13d
        and     ecx, 31
        shr     eax, cl
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.sra:
        mov     eax, r12d
        mov     ecx, r13d
        and     ecx, 31
        sar     eax, cl
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.slli:
        mov     eax, r12d
        mov     ecx, r14d
        and     ecx, 31
        shl     eax, cl
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.srli:
        mov     eax, r12d
        mov     ecx, r14d
        and     ecx, 31
        shr     eax, cl
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.srai:
        mov     eax, r12d
        mov     ecx, r14d
        and     ecx, 31
        sar     eax, cl
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.slt:
        cmp     r12d, r13d
        setl    al
        movzx   eax, al
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.sltu:
        cmp     r12d, r13d
        setb    al
        movzx   eax, al
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.slti:
        cmp     r12d, r14d
        setl    al
        movzx   eax, al
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.sltiu:
        cmp     r12d, r14d
        setb    al
        movzx   eax, al
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.beq:
        cmp     r12d, r13d
        jne     .nt
        jmp     .tk
.bne:
        cmp     r12d, r13d
        je      .nt
        jmp     .tk
.blt:
        cmp     r12d, r13d
        jge     .nt
        jmp     .tk
.bge:
        cmp     r12d, r13d
        jl      .nt
        jmp     .tk
.bltu:
        cmp     r12d, r13d
        jae     .nt
        jmp     .tk
.bgeu:
        cmp     r12d, r13d
        jb      .nt
.tk:
        mov     eax, r15d
        add     eax, r14d
        mov     edx, eax
        mov     eax, 1
        jmp     .leave
.nt:
        mov     eax, r15d
        add     eax, 4
        mov     edx, eax
        xor     eax, eax
        jmp     .leave
.jal:
        mov     eax, r15d
        add     eax, 4
        mov     [r9], eax
        mov     eax, r15d
        add     eax, r14d
        mov     edx, eax
        mov     eax, 1
        jmp     .leave
.jalr:
        mov     eax, r15d
        add     eax, 4
        mov     [r9], eax
        mov     eax, r12d
        add     eax, r14d
        and     eax, ~1
        mov     edx, eax
        mov     eax, 1
        jmp     .leave
.mul:
        mov     eax, r12d
        imul    r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.mulh:
        mov     eax, r12d
        imul    r13d
        mov     [r9], edx
        xor     eax, eax
        jmp     .leave
.mulhu:
        mov     eax, r12d
        mul     r13d
        mov     [r9], edx
        xor     eax, eax
        jmp     .leave
.mulhsu:
        movsxd  rax, r12d
        mov     ecx, r13d
        imul    rax, rcx
        shr     rax, 32
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.div:
        test    r13d, r13d
        jz      .d0
        cmp     r12d, 0x80000000
        jne     .dd
        cmp     r13d, -1
        je      .dov
.dd:
        mov     eax, r12d
        cdq
        idiv    r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.d0:
        mov     dword [r9], -1
        xor     eax, eax
        jmp     .leave
.dov:
        mov     dword [r9], 0x80000000
        xor     eax, eax
        jmp     .leave
.divu:
        test    r13d, r13d
        jz      .d0
        mov     eax, r12d
        xor     edx, edx
        div     r13d
        mov     [r9], eax
        xor     eax, eax
        jmp     .leave
.rem:
        test    r13d, r13d
        jz      .r0
        cmp     r12d, 0x80000000
        jne     .rd
        cmp     r13d, -1
        je      .rov
.rd:
        mov     eax, r12d
        cdq
        idiv    r13d
        mov     [r9], edx
        xor     eax, eax
        jmp     .leave
.r0:
        mov     [r9], r12d
        xor     eax, eax
        jmp     .leave
.rov:
        mov     dword [r9], 0
        xor     eax, eax
        jmp     .leave
.remu:
        test    r13d, r13d
        jz      .r0
        mov     eax, r12d
        xor     edx, edx
        div     r13d
        mov     [r9], edx
        xor     eax, eax
        jmp     .leave
.done:
        xor     eax, eax
.leave:
        ; edx = npc for branches; caller uses edx if eax==1
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
