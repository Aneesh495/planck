; src/core/bits.asm
; RV32 field extractors. Each takes inst in edi and returns in eax.
; Immediates are sign-extended to 32 bits.

        bits 64
        default rel

%include "macros.inc"
%include "rv32.inc"

        section .text

PROC inst_opcode
        mov     eax, edi
        and     eax, INST_OPC_MASK
        ret

PROC inst_rd
        mov     eax, edi
        shr     eax, INST_RD_SHIFT
        and     eax, INST_RD_MASK
        ret

PROC inst_rs1
        mov     eax, edi
        shr     eax, INST_RS1_SHIFT
        and     eax, INST_RS1_MASK
        ret

PROC inst_rs2
        mov     eax, edi
        shr     eax, INST_RS2_SHIFT
        and     eax, INST_RS2_MASK
        ret

PROC inst_funct3
        mov     eax, edi
        shr     eax, INST_F3_SHIFT
        and     eax, INST_F3_MASK
        ret

PROC inst_funct7
        mov     eax, edi
        shr     eax, INST_F7_SHIFT
        and     eax, INST_F7_MASK
        ret

PROC inst_shamt
        mov     eax, edi
        shr     eax, INST_RS2_SHIFT
        and     eax, INST_RS2_MASK
        ret

PROC inst_csr
        mov     eax, edi
        shr     eax, INST_CSR_SHIFT
        and     eax, INST_CSR_MASK
        ret

PROC inst_iimm
        mov     eax, edi
        sar     eax, 20
        ret

PROC inst_uimm
        mov     eax, edi
        and     eax, 0xFFFFF000
        ret

PROC inst_simm
        ; S: {inst[31:25], inst[11:7]}
        mov     eax, edi
        and     eax, 0xFE000000
        shr     eax, 20                 ; bits 11:5, not yet signed
        mov     ecx, edi
        shr     ecx, 7
        and     ecx, 0x1F
        or      eax, ecx
        shl     eax, 20
        sar     eax, 20
        ret

PROC inst_bimm
        ; B: inst[31]=imm[12], inst[7]=imm[11], inst[30:25]=imm[10:5], inst[11:8]=imm[4:1], 0
        xor     eax, eax
        mov     ecx, edi
        ; imm[12] from bit 31 → bit 12
        test    ecx, 0x80000000
        jz      .n12
        or      eax, (1 << 12)
.n12:
        test    ecx, (1 << 7)
        jz      .n11
        or      eax, (1 << 11)
.n11:
        ; inst[30:25] → imm[10:5]
        mov     edx, ecx
        shr     edx, 20
        and     edx, 0x7E0              ; bits 10:5
        or      eax, edx
        ; inst[11:8] → imm[4:1]
        mov     edx, ecx
        shr     edx, 7
        and     edx, 0x1E
        or      eax, edx
        ; sign extend from bit 12
        shl     eax, 19
        sar     eax, 19
        ret

PROC inst_jimm
        ; J: inst[31]=imm[20], inst[19:12]=imm[19:12], inst[20]=imm[11], inst[30:21]=imm[10:1]
        xor     eax, eax
        mov     ecx, edi
        test    ecx, 0x80000000
        jz      .n20
        or      eax, (1 << 20)
.n20:
        mov     edx, ecx
        and     edx, 0x000FF000         ; already imm[19:12]
        or      eax, edx
        test    ecx, (1 << 20)
        jz      .n11
        or      eax, (1 << 11)
.n11:
        mov     edx, ecx
        shr     edx, 20
        and     edx, 0x7FE              ; imm[10:1]
        or      eax, edx
        shl     eax, 11
        sar     eax, 11
        ret

; int fits_i12(int32 v)  — 1 if v == sext12(v)
PROC fits_i12
        mov     eax, edi
        shl     eax, 20
        sar     eax, 20
        cmp     eax, edi
        sete    al
        movzx   eax, al
        ret

; int fits_b13(int32 v)  — 13-bit signed, LSB must be 0
PROC fits_b13
        test    edi, 1
        jnz     .no
        mov     eax, edi
        shl     eax, 19
        sar     eax, 19
        cmp     eax, edi
        sete    al
        movzx   eax, al
        ret
.no:
        xor     eax, eax
        ret

; int fits_j21(int32 v)
PROC fits_j21
        test    edi, 1
        jnz     .no
        mov     eax, edi
        shl     eax, 11
        sar     eax, 11
        cmp     eax, edi
        sete    al
        movzx   eax, al
        ret
.no:
        xor     eax, eax
        ret

; uint32 pack_r(rd, rs1, rs2, f3, f7, opc)
; rdi rd, rsi rs1, rdx rs2, rcx f3, r8 f7, r9 opc
PROC pack_r
        mov     eax, r9d
        shl     edi, INST_RD_SHIFT
        or      eax, edi
        shl     ecx, INST_F3_SHIFT
        or      eax, ecx
        shl     esi, INST_RS1_SHIFT
        or      eax, esi
        shl     edx, INST_RS2_SHIFT
        or      eax, edx
        shl     r8d, INST_F7_SHIFT
        or      eax, r8d
        ret

; uint32 pack_i(rd, rs1, imm, f3, opc)
; rdi rd, rsi rs1, rdx imm, rcx f3, r8 opc
PROC pack_i
        mov     eax, r8d
        shl     edi, INST_RD_SHIFT
        or      eax, edi
        shl     ecx, INST_F3_SHIFT
        or      eax, ecx
        shl     esi, INST_RS1_SHIFT
        or      eax, esi
        shl     edx, 20
        or      eax, edx
        ret

; uint32 pack_s(rs1, rs2, imm, f3, opc)
; rdi rs1, rsi rs2, rdx imm, rcx f3, r8 opc
PROC pack_s
        mov     eax, r8d
        shl     ecx, INST_F3_SHIFT
        or      eax, ecx
        shl     edi, INST_RS1_SHIFT
        or      eax, edi
        shl     esi, INST_RS2_SHIFT
        or      eax, esi
        mov     ecx, edx
        and     ecx, 0x1F
        shl     ecx, 7
        or      eax, ecx
        mov     ecx, edx
        and     ecx, 0xFE0
        shl     ecx, 20                 ; imm[11:5] to bits 31:25: imm[11:5] is bits 11:5, shl 20 → 31:25
        or      eax, ecx
        ret

; uint32 pack_b(rs1, rs2, imm, f3, opc)
; rdi rs1, rsi rs2, rdx imm, rcx f3, r8 opc
PROC pack_b
        mov     eax, r8d
        shl     ecx, INST_F3_SHIFT
        or      eax, ecx
        shl     edi, INST_RS1_SHIFT
        or      eax, edi
        shl     esi, INST_RS2_SHIFT
        or      eax, esi
        ; imm[11] → bit 7
        mov     ecx, edx
        and     ecx, (1 << 11)
        shr     ecx, 4
        or      eax, ecx
        ; imm[4:1] → bits 11:8
        mov     ecx, edx
        and     ecx, 0x1E
        shl     ecx, 7
        or      eax, ecx
        ; imm[10:5] → bits 30:25
        mov     ecx, edx
        and     ecx, 0x7E0
        shl     ecx, 20
        or      eax, ecx
        ; imm[12] → bit 31
        mov     ecx, edx
        and     ecx, (1 << 12)
        shl     ecx, 19
        or      eax, ecx
        ret

; uint32 pack_u(rd, imm, opc)  imm already in [31:12]
; rdi rd, rsi imm, rdx opc
PROC pack_u
        mov     eax, edx
        shl     edi, INST_RD_SHIFT
        or      eax, edi
        mov     ecx, esi
        and     ecx, 0xFFFFF000
        or      eax, ecx
        ret

; uint32 pack_j(rd, imm, opc)
; rdi rd, rsi imm, rdx opc
PROC pack_j
        mov     eax, edx
        shl     edi, INST_RD_SHIFT
        or      eax, edi
        ; imm[20] → 31
        mov     ecx, esi
        and     ecx, (1 << 20)
        shl     ecx, 11
        or      eax, ecx
        ; imm[10:1] → 30:21
        mov     ecx, esi
        and     ecx, 0x7FE
        shl     ecx, 20
        or      eax, ecx
        ; imm[11] → 20
        mov     ecx, esi
        and     ecx, (1 << 11)
        shl     ecx, 9
        or      eax, ecx
        ; imm[19:12] → 19:12
        mov     ecx, esi
        and     ecx, 0xFF000
        or      eax, ecx
        ret

; uint32 lui_hi(int32 imm)  — for li expansion: hi of lui given full 32-bit imm
PROC lui_hi
        mov     eax, edi
        ; lo = sext12(imm[11:0]); hi = (imm - lo) >> 12
        mov     ecx, edi
        shl     ecx, 20
        sar     ecx, 20
        sub     eax, ecx
        sar     eax, 12
        and     eax, 0xFFFFF
        ret
