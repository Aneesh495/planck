; src/core/decode.asm
; RV32IM decoder. Fills a dec_t. Illegal encodings set DEC_ILLEGAL and ID_ILLEGAL.

        bits 64
        default rel

%include "macros.inc"
%include "rv32.inc"

        extern inst_opcode
        extern inst_rd
        extern inst_rs1
        extern inst_rs2
        extern inst_funct3
        extern inst_funct7
        extern inst_shamt
        extern inst_csr
        extern inst_iimm
        extern inst_uimm
        extern inst_simm
        extern inst_bimm
        extern inst_jimm

        section .text

; void decode_clear(dec_t*)
PROC decode_clear
        xor     eax, eax
        mov     ecx, DEC_SIZEOF / 4
        mov     r8, rdi
.rep:
        mov     [rdi], eax
        add     rdi, 4
        dec     ecx
        jnz     .rep
        mov     dword [r8 + DEC_SIZE], 4
        ret

; int decode_inst(uint32 inst, uint32 pc, dec_t *out)
; returns 0 ok, -1 illegal (still fills out)
PROC decode_inst
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     r12d, edi               ; inst
        mov     r13d, esi               ; pc
        mov     r14, rdx                ; out
        mov     rdi, r14
        call    decode_clear
        mov     [r14 + DEC_RAW], r12d
        mov     [r14 + DEC_PC], r13d
        mov     edi, r12d
        call    inst_opcode
        mov     ebx, eax                ; opc
        mov     edi, r12d
        call    inst_rd
        mov     [r14 + DEC_RD], eax
        mov     edi, r12d
        call    inst_rs1
        mov     [r14 + DEC_RS1], eax
        mov     edi, r12d
        call    inst_rs2
        mov     [r14 + DEC_RS2], eax
        mov     edi, r12d
        call    inst_funct3
        mov     r13d, eax               ; f3 (pc no longer needed)
        mov     edi, r12d
        call    inst_funct7
        mov     r8d, eax                ; f7

        cmp     ebx, OPC_LUI
        je      .lui
        cmp     ebx, OPC_AUIPC
        je      .auipc
        cmp     ebx, OPC_JAL
        je      .jal
        cmp     ebx, OPC_JALR
        je      .jalr
        cmp     ebx, OPC_BRANCH
        je      .br
        cmp     ebx, OPC_LOAD
        je      .load
        cmp     ebx, OPC_STORE
        je      .store
        cmp     ebx, OPC_OP_IMM
        je      .opimm
        cmp     ebx, OPC_OP
        je      .op
        cmp     ebx, OPC_MISC_MEM
        je      .fence
        cmp     ebx, OPC_SYSTEM
        je      .sys
        jmp     .ill

.lui:
        mov     dword [r14 + DEC_ID], ID_LUI
        mov     edi, r12d
        call    inst_uimm
        mov     [r14 + DEC_IMM], eax
        jmp     .ok

.auipc:
        mov     dword [r14 + DEC_ID], ID_AUIPC
        mov     edi, r12d
        call    inst_uimm
        mov     [r14 + DEC_IMM], eax
        jmp     .ok

.jal:
        mov     dword [r14 + DEC_ID], ID_JAL
        mov     edi, r12d
        call    inst_jimm
        mov     [r14 + DEC_IMM], eax
        jmp     .ok

.jalr:
        cmp     r13d, F3_BEQ            ; funct3 must be 000
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_JALR
        mov     edi, r12d
        call    inst_iimm
        mov     [r14 + DEC_IMM], eax
        jmp     .ok

.br:
        mov     edi, r12d
        call    inst_bimm
        mov     [r14 + DEC_IMM], eax
        cmp     r13d, F3_BEQ
        jne     .br1
        mov     dword [r14 + DEC_ID], ID_BEQ
        jmp     .ok
.br1:   cmp     r13d, F3_BNE
        jne     .br2
        mov     dword [r14 + DEC_ID], ID_BNE
        jmp     .ok
.br2:   cmp     r13d, F3_BLT
        jne     .br3
        mov     dword [r14 + DEC_ID], ID_BLT
        jmp     .ok
.br3:   cmp     r13d, F3_BGE
        jne     .br4
        mov     dword [r14 + DEC_ID], ID_BGE
        jmp     .ok
.br4:   cmp     r13d, F3_BLTU
        jne     .br5
        mov     dword [r14 + DEC_ID], ID_BLTU
        jmp     .ok
.br5:   cmp     r13d, F3_BGEU
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_BGEU
        jmp     .ok

.load:
        mov     edi, r12d
        call    inst_iimm
        mov     [r14 + DEC_IMM], eax
        cmp     r13d, F3_LB
        jne     .ld1
        mov     dword [r14 + DEC_ID], ID_LB
        jmp     .ok
.ld1:   cmp     r13d, F3_LH
        jne     .ld2
        mov     dword [r14 + DEC_ID], ID_LH
        jmp     .ok
.ld2:   cmp     r13d, F3_LW
        jne     .ld3
        mov     dword [r14 + DEC_ID], ID_LW
        jmp     .ok
.ld3:   cmp     r13d, F3_LBU
        jne     .ld4
        mov     dword [r14 + DEC_ID], ID_LBU
        jmp     .ok
.ld4:   cmp     r13d, F3_LHU
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_LHU
        jmp     .ok

.store:
        mov     edi, r12d
        call    inst_simm
        mov     [r14 + DEC_IMM], eax
        cmp     r13d, F3_SB
        jne     .st1
        mov     dword [r14 + DEC_ID], ID_SB
        jmp     .ok
.st1:   cmp     r13d, F3_SH
        jne     .st2
        mov     dword [r14 + DEC_ID], ID_SH
        jmp     .ok
.st2:   cmp     r13d, F3_SW
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_SW
        jmp     .ok

.opimm:
        mov     edi, r12d
        call    inst_iimm
        mov     [r14 + DEC_IMM], eax
        cmp     r13d, F3_ADDI
        jne     .oi1
        mov     dword [r14 + DEC_ID], ID_ADDI
        jmp     .ok
.oi1:   cmp     r13d, F3_SLTI
        jne     .oi2
        mov     dword [r14 + DEC_ID], ID_SLTI
        jmp     .ok
.oi2:   cmp     r13d, F3_SLTIU
        jne     .oi3
        mov     dword [r14 + DEC_ID], ID_SLTIU
        jmp     .ok
.oi3:   cmp     r13d, F3_XORI
        jne     .oi4
        mov     dword [r14 + DEC_ID], ID_XORI
        jmp     .ok
.oi4:   cmp     r13d, F3_ORI
        jne     .oi5
        mov     dword [r14 + DEC_ID], ID_ORI
        jmp     .ok
.oi5:   cmp     r13d, F3_ANDI
        jne     .oi6
        mov     dword [r14 + DEC_ID], ID_ANDI
        jmp     .ok
.oi6:   cmp     r13d, F3_SLLI
        jne     .oi7
        cmp     r8d, F7_ADD
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_SLLI
        mov     edi, r12d
        call    inst_shamt
        mov     [r14 + DEC_IMM], eax
        jmp     .ok
.oi7:   cmp     r13d, F3_SRLI
        jne     .ill
        cmp     r8d, F7_ADD
        je      .srli
        cmp     r8d, F7_SRA
        je      .srai
        jmp     .ill
.srli:
        mov     dword [r14 + DEC_ID], ID_SRLI
        mov     edi, r12d
        call    inst_shamt
        mov     [r14 + DEC_IMM], eax
        jmp     .ok
.srai:
        mov     dword [r14 + DEC_ID], ID_SRAI
        mov     edi, r12d
        call    inst_shamt
        mov     [r14 + DEC_IMM], eax
        jmp     .ok

.op:
        cmp     r8d, F7_MUL
        je      .mop
        cmp     r8d, F7_ADD
        je      .op0
        cmp     r8d, F7_SUB
        je      .op20
        jmp     .ill
.op0:
        cmp     r13d, F3_ADD
        jne     .o1
        mov     dword [r14 + DEC_ID], ID_ADD
        jmp     .ok
.o1:    cmp     r13d, F3_SLL
        jne     .o2
        mov     dword [r14 + DEC_ID], ID_SLL
        jmp     .ok
.o2:    cmp     r13d, F3_SLT
        jne     .o3
        mov     dword [r14 + DEC_ID], ID_SLT
        jmp     .ok
.o3:    cmp     r13d, F3_SLTU
        jne     .o4
        mov     dword [r14 + DEC_ID], ID_SLTU
        jmp     .ok
.o4:    cmp     r13d, F3_XOR
        jne     .o5
        mov     dword [r14 + DEC_ID], ID_XOR
        jmp     .ok
.o5:    cmp     r13d, F3_SRL
        jne     .o6
        mov     dword [r14 + DEC_ID], ID_SRL
        jmp     .ok
.o6:    cmp     r13d, F3_OR
        jne     .o7
        mov     dword [r14 + DEC_ID], ID_OR
        jmp     .ok
.o7:    cmp     r13d, F3_AND
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_AND
        jmp     .ok
.op20:
        cmp     r13d, F3_ADD
        je      .sub
        cmp     r13d, F3_SRL
        je      .sra
        jmp     .ill
.sub:
        mov     dword [r14 + DEC_ID], ID_SUB
        jmp     .ok
.sra:
        mov     dword [r14 + DEC_ID], ID_SRA
        jmp     .ok
.mop:
        cmp     r13d, F3_MUL
        jne     .m1
        mov     dword [r14 + DEC_ID], ID_MUL
        jmp     .ok
.m1:    cmp     r13d, F3_MULH
        jne     .m2
        mov     dword [r14 + DEC_ID], ID_MULH
        jmp     .ok
.m2:    cmp     r13d, F3_MULHSU
        jne     .m3
        mov     dword [r14 + DEC_ID], ID_MULHSU
        jmp     .ok
.m3:    cmp     r13d, F3_MULHU
        jne     .m4
        mov     dword [r14 + DEC_ID], ID_MULHU
        jmp     .ok
.m4:    cmp     r13d, F3_DIV
        jne     .m5
        mov     dword [r14 + DEC_ID], ID_DIV
        jmp     .ok
.m5:    cmp     r13d, F3_DIVU
        jne     .m6
        mov     dword [r14 + DEC_ID], ID_DIVU
        jmp     .ok
.m6:    cmp     r13d, F3_REM
        jne     .m7
        mov     dword [r14 + DEC_ID], ID_REM
        jmp     .ok
.m7:    cmp     r13d, F3_REMU
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_REMU
        jmp     .ok

.fence:
        cmp     r13d, F3_FENCE
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_FENCE
        jmp     .ok

.sys:
        cmp     r13d, F3_PRIV
        je      .priv
        mov     edi, r12d
        call    inst_csr
        mov     [r14 + DEC_CSR], eax
        mov     edi, r12d
        call    inst_iimm
        ; rs1 already set; for immediate CSR the uimm is rs1 field
        cmp     r13d, F3_CSRRW
        jne     .c1
        mov     dword [r14 + DEC_ID], ID_CSRRW
        jmp     .ok
.c1:    cmp     r13d, F3_CSRRS
        jne     .c2
        mov     dword [r14 + DEC_ID], ID_CSRRS
        jmp     .ok
.c2:    cmp     r13d, F3_CSRRC
        jne     .c3
        mov     dword [r14 + DEC_ID], ID_CSRRC
        jmp     .ok
.c3:    cmp     r13d, F3_CSRRWI
        jne     .c4
        mov     dword [r14 + DEC_ID], ID_CSRRWI
        jmp     .ok
.c4:    cmp     r13d, F3_CSRRSI
        jne     .c5
        mov     dword [r14 + DEC_ID], ID_CSRRSI
        jmp     .ok
.c5:    cmp     r13d, F3_CSRRCI
        jne     .ill
        mov     dword [r14 + DEC_ID], ID_CSRRCI
        jmp     .ok
.priv:
        ; ecall 0x00000073, ebreak 0x00100073, mret 0x30200073
        cmp     r12d, 0x00000073
        je      .ecall
        cmp     r12d, 0x00100073
        je      .ebreak
        cmp     r12d, 0x30200073
        je      .mret
        jmp     .ill
.ecall:
        mov     dword [r14 + DEC_ID], ID_ECALL
        jmp     .ok
.ebreak:
        mov     dword [r14 + DEC_ID], ID_EBREAK
        jmp     .ok
.mret:
        mov     dword [r14 + DEC_ID], ID_MRET
        jmp     .ok

.ill:
        mov     dword [r14 + DEC_ID], ID_ILLEGAL
        mov     dword [r14 + DEC_ILLEGAL], 1
        mov     eax, -1
        jmp     .out
.ok:
        xor     eax, eax
.out:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
