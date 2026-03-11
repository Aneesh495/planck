; src/asm/tables.asm
; Register ABI names and RV32IM mnemonic table for the assembler.

        bits 64
        default rel

%include "macros.inc"
%include "rv32.inc"

        extern str_eq_n

        section .rodata

; forms
global FORM_R, FORM_I, FORM_S, FORM_B, FORM_U, FORM_J, FORM_ISH, FORM_SYS, FORM_CSR, FORM_PSEUDO
FORM_R          equ 0
FORM_I          equ 1
FORM_S          equ 2
FORM_B          equ 3
FORM_U          equ 4
FORM_J          equ 5
FORM_ISH        equ 6
FORM_SYS        equ 7
FORM_CSR        equ 8
FORM_PSEUDO     equ 9
FORM_LOAD       equ 10
FORM_NONE       equ 11

; name, nlen, id, form, opc, f3, f7  — 32-byte records
; MNEM_NAME 0, NLEN 8, ID 12, FORM 16, OPC 20, F3 24, F7 28
MNEM_NAME       equ 0
MNEM_NLEN       equ 8
MNEM_ID         equ 12
MNEM_FORM       equ 16
MNEM_OPC        equ 20
MNEM_F3         equ 24
MNEM_F7         equ 28
MNEM_SIZE       equ 32

%macro NM 1
nm_%1: db %str(%1)
%endmacro

; We emit names then a table of pointers. NASM %str isn't portable.
; Hand-written names:

n_lui:          db "lui"
n_auipc:        db "auipc"
n_jal:          db "jal"
n_jalr:         db "jalr"
n_beq:          db "beq"
n_bne:          db "bne"
n_blt:          db "blt"
n_bge:          db "bge"
n_bltu:         db "bltu"
n_bgeu:         db "bgeu"
n_lb:           db "lb"
n_lh:           db "lh"
n_lw:           db "lw"
n_lbu:          db "lbu"
n_lhu:          db "lhu"
n_sb:           db "sb"
n_sh:           db "sh"
n_sw:           db "sw"
n_addi:         db "addi"
n_slti:         db "slti"
n_sltiu:        db "sltiu"
n_xori:         db "xori"
n_ori:          db "ori"
n_andi:         db "andi"
n_slli:         db "slli"
n_srli:         db "srli"
n_srai:         db "srai"
n_add:          db "add"
n_sub:          db "sub"
n_sll:          db "sll"
n_slt:          db "slt"
n_sltu:         db "sltu"
n_xor:          db "xor"
n_srl:          db "srl"
n_sra:          db "sra"
n_or:           db "or"
n_and:          db "and"
n_fence:        db "fence"
n_ecall:        db "ecall"
n_ebreak:       db "ebreak"
n_csrrw:        db "csrrw"
n_csrrs:        db "csrrs"
n_csrrc:        db "csrrc"
n_csrrwi:       db "csrrwi"
n_csrrsi:       db "csrrsi"
n_csrrci:       db "csrrci"
n_mul:          db "mul"
n_mulh:         db "mulh"
n_mulhsu:       db "mulhsu"
n_mulhu:        db "mulhu"
n_div:          db "div"
n_divu:         db "divu"
n_rem:          db "rem"
n_remu:         db "remu"
n_mret:         db "mret"
n_nop:          db "nop"
n_li:           db "li"
n_mv:           db "mv"
n_not:          db "not"
n_neg:          db "neg"
n_seqz:         db "seqz"
n_snez:         db "snez"
n_sltz:         db "sltz"
n_sgtz:         db "sgtz"
n_beqz:         db "beqz"
n_bnez:         db "bnez"
n_blez:         db "blez"
n_bgez:         db "bgez"
n_bltz:         db "bltz"
n_bgtz:         db "bgtz"
n_bgt:          db "bgt"
n_ble:          db "ble"
n_bgtu:         db "bgtu"
n_bleu:         db "bleu"
n_j:            db "j"
n_jr:           db "jr"
n_ret:          db "ret"
n_call:         db "call"
n_tail:         db "tail"
n_la:           db "la"

        align 8
        global mnem_tab, mnem_count
mnem_tab:
        ; name ptr, pad to 8, nlen, id, form, opc, f3, f7
%macro M 7
        dq %1
        dd %2, %3, %4, %5, %6, %7
%endmacro
        ;     name     nlen id        form      opc         f3        f7
        M n_lui,    3, ID_LUI,    FORM_U,   OPC_LUI,     0,         0
        M n_auipc,  5, ID_AUIPC,  FORM_U,   OPC_AUIPC,   0,         0
        M n_jal,    3, ID_JAL,    FORM_J,   OPC_JAL,     0,         0
        M n_jalr,   4, ID_JALR,   FORM_I,   OPC_JALR,    0,         0
        M n_beq,    3, ID_BEQ,    FORM_B,   OPC_BRANCH,  F3_BEQ,    0
        M n_bne,    3, ID_BNE,    FORM_B,   OPC_BRANCH,  F3_BNE,    0
        M n_blt,    3, ID_BLT,    FORM_B,   OPC_BRANCH,  F3_BLT,    0
        M n_bge,    3, ID_BGE,    FORM_B,   OPC_BRANCH,  F3_BGE,    0
        M n_bltu,   4, ID_BLTU,   FORM_B,   OPC_BRANCH,  F3_BLTU,   0
        M n_bgeu,   4, ID_BGEU,   FORM_B,   OPC_BRANCH,  F3_BGEU,   0
        M n_lb,     2, ID_LB,     FORM_LOAD,OPC_LOAD,    F3_LB,     0
        M n_lh,     2, ID_LH,     FORM_LOAD,OPC_LOAD,    F3_LH,     0
        M n_lw,     2, ID_LW,     FORM_LOAD,OPC_LOAD,    F3_LW,     0
        M n_lbu,    3, ID_LBU,    FORM_LOAD,OPC_LOAD,    F3_LBU,    0
        M n_lhu,    3, ID_LHU,    FORM_LOAD,OPC_LOAD,    F3_LHU,    0
        M n_sb,     2, ID_SB,     FORM_S,   OPC_STORE,   F3_SB,     0
        M n_sh,     2, ID_SH,     FORM_S,   OPC_STORE,   F3_SH,     0
        M n_sw,     2, ID_SW,     FORM_S,   OPC_STORE,   F3_SW,     0
        M n_addi,   4, ID_ADDI,   FORM_I,   OPC_OP_IMM,  F3_ADDI,   0
        M n_slti,   4, ID_SLTI,   FORM_I,   OPC_OP_IMM,  F3_SLTI,   0
        M n_sltiu,  5, ID_SLTIU,  FORM_I,   OPC_OP_IMM,  F3_SLTIU,  0
        M n_xori,   4, ID_XORI,   FORM_I,   OPC_OP_IMM,  F3_XORI,   0
        M n_ori,    3, ID_ORI,    FORM_I,   OPC_OP_IMM,  F3_ORI,    0
        M n_andi,   4, ID_ANDI,   FORM_I,   OPC_OP_IMM,  F3_ANDI,   0
        M n_slli,   4, ID_SLLI,   FORM_ISH, OPC_OP_IMM,  F3_SLLI,   F7_ADD
        M n_srli,   4, ID_SRLI,   FORM_ISH, OPC_OP_IMM,  F3_SRLI,   F7_ADD
        M n_srai,   4, ID_SRAI,   FORM_ISH, OPC_OP_IMM,  F3_SRAI,   F7_SRA
        M n_add,    3, ID_ADD,    FORM_R,   OPC_OP,      F3_ADD,    F7_ADD
        M n_sub,    3, ID_SUB,    FORM_R,   OPC_OP,      F3_ADD,    F7_SUB
        M n_sll,    3, ID_SLL,    FORM_R,   OPC_OP,      F3_SLL,    F7_ADD
        M n_slt,    3, ID_SLT,    FORM_R,   OPC_OP,      F3_SLT,    F7_ADD
        M n_sltu,   4, ID_SLTU,   FORM_R,   OPC_OP,      F3_SLTU,   F7_ADD
        M n_xor,    3, ID_XOR,    FORM_R,   OPC_OP,      F3_XOR,    F7_ADD
        M n_srl,    3, ID_SRL,    FORM_R,   OPC_OP,      F3_SRL,    F7_ADD
        M n_sra,    3, ID_SRA,    FORM_R,   OPC_OP,      F3_SRL,    F7_SRA
        M n_or,     2, ID_OR,     FORM_R,   OPC_OP,      F3_OR,     F7_ADD
        M n_and,    3, ID_AND,    FORM_R,   OPC_OP,      F3_AND,    F7_ADD
        M n_fence,  5, ID_FENCE,  FORM_NONE,OPC_MISC_MEM,0,         0
        M n_ecall,  5, ID_ECALL,  FORM_NONE,OPC_SYSTEM,  0,         0
        M n_ebreak, 6, ID_EBREAK, FORM_NONE,OPC_SYSTEM,  0,         1
        M n_csrrw,  5, ID_CSRRW,  FORM_CSR, OPC_SYSTEM,  F3_CSRRW,  0
        M n_csrrs,  5, ID_CSRRS,  FORM_CSR, OPC_SYSTEM,  F3_CSRRS,  0
        M n_csrrc,  5, ID_CSRRC,  FORM_CSR, OPC_SYSTEM,  F3_CSRRC,  0
        M n_csrrwi, 6, ID_CSRRWI, FORM_CSR, OPC_SYSTEM,  F3_CSRRWI, 0
        M n_csrrsi, 6, ID_CSRRSI, FORM_CSR, OPC_SYSTEM,  F3_CSRRSI, 0
        M n_csrrci, 6, ID_CSRRCI, FORM_CSR, OPC_SYSTEM,  F3_CSRRCI, 0
        M n_mul,    3, ID_MUL,    FORM_R,   OPC_OP,      F3_MUL,    F7_MUL
        M n_mulh,   4, ID_MULH,   FORM_R,   OPC_OP,      F3_MULH,   F7_MUL
        M n_mulhsu, 6, ID_MULHSU, FORM_R,   OPC_OP,      F3_MULHSU, F7_MUL
        M n_mulhu,  5, ID_MULHU,  FORM_R,   OPC_OP,      F3_MULHU,  F7_MUL
        M n_div,    3, ID_DIV,    FORM_R,   OPC_OP,      F3_DIV,    F7_MUL
        M n_divu,   4, ID_DIVU,   FORM_R,   OPC_OP,      F3_DIVU,   F7_MUL
        M n_rem,    3, ID_REM,    FORM_R,   OPC_OP,      F3_REM,    F7_MUL
        M n_remu,   4, ID_REMU,   FORM_R,   OPC_OP,      F3_REMU,   F7_MUL
        M n_mret,   4, ID_MRET,   FORM_NONE,OPC_SYSTEM,  0,         F7_MRET
        M n_nop,    3, 0,         FORM_PSEUDO,0,0,0
        M n_li,     2, 0,         FORM_PSEUDO,0,0,0
        M n_mv,     2, 0,         FORM_PSEUDO,0,0,0
        M n_not,    3, 0,         FORM_PSEUDO,0,0,0
        M n_neg,    3, 0,         FORM_PSEUDO,0,0,0
        M n_seqz,   4, 0,         FORM_PSEUDO,0,0,0
        M n_snez,   4, 0,         FORM_PSEUDO,0,0,0
        M n_sltz,   4, 0,         FORM_PSEUDO,0,0,0
        M n_sgtz,   4, 0,         FORM_PSEUDO,0,0,0
        M n_beqz,   4, 0,         FORM_PSEUDO,0,0,0
        M n_bnez,   4, 0,         FORM_PSEUDO,0,0,0
        M n_blez,   4, 0,         FORM_PSEUDO,0,0,0
        M n_bgez,   4, 0,         FORM_PSEUDO,0,0,0
        M n_bltz,   4, 0,         FORM_PSEUDO,0,0,0
        M n_bgtz,   4, 0,         FORM_PSEUDO,0,0,0
        M n_bgt,    3, 0,         FORM_PSEUDO,0,0,0
        M n_ble,    3, 0,         FORM_PSEUDO,0,0,0
        M n_bgtu,   4, 0,         FORM_PSEUDO,0,0,0
        M n_bleu,   4, 0,         FORM_PSEUDO,0,0,0
        M n_j,      1, 0,         FORM_PSEUDO,0,0,0
        M n_jr,     2, 0,         FORM_PSEUDO,0,0,0
        M n_ret,    3, 0,         FORM_PSEUDO,0,0,0
        M n_call,   4, 0,         FORM_PSEUDO,0,0,0
        M n_tail,   4, 0,         FORM_PSEUDO,0,0,0
        M n_la,     2, 0,         FORM_PSEUDO,0,0,0
mnem_end:
mnem_count:
        dd (mnem_end - mnem_tab) / MNEM_SIZE

; registers: name, nlen, number
REG_NAME        equ 0
REG_NLEN        equ 8
REG_NUM         equ 12
REG_SIZE        equ 16

n_zero: db "zero"
n_ra:   db "ra"
n_sp:   db "sp"
n_gp:   db "gp"
n_tp:   db "tp"
n_t0:   db "t0"
n_t1:   db "t1"
n_t2:   db "t2"
n_s0:   db "s0"
n_fp:   db "fp"
n_s1:   db "s1"
n_a0:   db "a0"
n_a1:   db "a1"
n_a2:   db "a2"
n_a3:   db "a3"
n_a4:   db "a4"
n_a5:   db "a5"
n_a6:   db "a6"
n_a7:   db "a7"
n_s2:   db "s2"
n_s3:   db "s3"
n_s4:   db "s4"
n_s5:   db "s5"
n_s6:   db "s6"
n_s7:   db "s7"
n_s8:   db "s8"
n_s9:   db "s9"
n_s10:  db "s10"
n_s11:  db "s11"
n_t3:   db "t3"
n_t4:   db "t4"
n_t5:   db "t5"
n_t6:   db "t6"
n_x0:   db "x0"
n_x1:   db "x1"
n_x2:   db "x2"
n_x3:   db "x3"
n_x4:   db "x4"
n_x5:   db "x5"
n_x6:   db "x6"
n_x7:   db "x7"
n_x8:   db "x8"
n_x9:   db "x9"
n_x10:  db "x10"
n_x11:  db "x11"
n_x12:  db "x12"
n_x13:  db "x13"
n_x14:  db "x14"
n_x15:  db "x15"
n_x16:  db "x16"
n_x17:  db "x17"
n_x18:  db "x18"
n_x19:  db "x19"
n_x20:  db "x20"
n_x21:  db "x21"
n_x22:  db "x22"
n_x23:  db "x23"
n_x24:  db "x24"
n_x25:  db "x25"
n_x26:  db "x26"
n_x27:  db "x27"
n_x28:  db "x28"
n_x29:  db "x29"
n_x30:  db "x30"
n_x31:  db "x31"

%macro R 3
        dq %1
        dd %2, %3
%endmacro

        global reg_tab, reg_count
        align 8
reg_tab:
        R n_zero,4,0
        R n_ra,2,1
        R n_sp,2,2
        R n_gp,2,3
        R n_tp,2,4
        R n_t0,2,5
        R n_t1,2,6
        R n_t2,2,7
        R n_s0,2,8
        R n_fp,2,8
        R n_s1,2,9
        R n_a0,2,10
        R n_a1,2,11
        R n_a2,2,12
        R n_a3,2,13
        R n_a4,2,14
        R n_a5,2,15
        R n_a6,2,16
        R n_a7,2,17
        R n_s2,2,18
        R n_s3,2,19
        R n_s4,2,20
        R n_s5,2,21
        R n_s6,2,22
        R n_s7,2,23
        R n_s8,2,24
        R n_s9,2,25
        R n_s10,3,26
        R n_s11,3,27
        R n_t3,2,28
        R n_t4,2,29
        R n_t5,2,30
        R n_t6,2,31
        R n_x0,2,0
        R n_x1,2,1
        R n_x2,2,2
        R n_x3,2,3
        R n_x4,2,4
        R n_x5,2,5
        R n_x6,2,6
        R n_x7,2,7
        R n_x8,2,8
        R n_x9,2,9
        R n_x10,3,10
        R n_x11,3,11
        R n_x12,3,12
        R n_x13,3,13
        R n_x14,3,14
        R n_x15,3,15
        R n_x16,3,16
        R n_x17,3,17
        R n_x18,3,18
        R n_x19,3,19
        R n_x20,3,20
        R n_x21,3,21
        R n_x22,3,22
        R n_x23,3,23
        R n_x24,3,24
        R n_x25,3,25
        R n_x26,3,26
        R n_x27,3,27
        R n_x28,3,28
        R n_x29,3,29
        R n_x30,3,30
        R n_x31,3,31
reg_end:
reg_count:
        dd (reg_end - reg_tab) / REG_SIZE

        section .text

; lowercase a byte in al
fold:
        cmp     al, 'A'
        jb      .r
        cmp     al, 'Z'
        ja      .r
        or      al, 32
.r:     ret

; int ieq_n(a, alen, b, blen)  case-insensitive
ieq_n:
        cmp     esi, ecx
        jne     .no
        test    esi, esi
        jz      .yes
.loop:
        mov     al, [rdi]
        mov     ah, [rdx]
        push    rdx
        call    fold
        mov     cl, al
        mov     al, ah
        call    fold
        cmp     cl, al
        pop     rdx
        jne     .no
        inc     rdi
        inc     rdx
        dec     esi
        jnz     .loop
.yes:
        mov     eax, 1
        ret
.no:
        xor     eax, eax
        ret

; int mnem_lookup(const char *s, int len, mnem_rec *out_copy)
; returns 0 hit (copies 32 bytes to out), -1 miss
        global mnem_lookup
PROC mnem_lookup
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     r12, rdi
        mov     r13d, esi
        mov     r14, rdx
        lea     rbx, [rel mnem_tab]
        mov     eax, [rel mnem_count]
        xor     r8d, r8d
.loop:
        cmp     r8d, eax
        jge     .miss
        mov     rdi, r12
        mov     esi, r13d
        mov     rdx, [rbx + MNEM_NAME]
        mov     ecx, [rbx + MNEM_NLEN]
        push    rax
        push    r8
        call    ieq_n
        pop     r8
        pop     rcx                     ; count
        test    eax, eax
        jnz     .hit
        add     rbx, MNEM_SIZE
        inc     r8d
        mov     eax, ecx
        jmp     .loop
.hit:
        ; copy 32 bytes
        mov     rdi, r14
        mov     rsi, rbx
        mov     ecx, 4
.rep:
        mov     rax, [rsi]
        mov     [rdi], rax
        add     rsi, 8
        add     rdi, 8
        dec     ecx
        jnz     .rep
        xor     eax, eax
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
.miss:
        mov     eax, -1
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; int reg_lookup(const char *s, int len)  → 0..31 or -1
        global reg_lookup
PROC reg_lookup
        push    rbx
        push    r12
        push    r13
        mov     r12, rdi
        mov     r13d, esi
        lea     rbx, [rel reg_tab]
        mov     eax, [rel reg_count]
        xor     r8d, r8d
.loop:
        cmp     r8d, eax
        jge     .miss
        mov     rdi, r12
        mov     esi, r13d
        mov     rdx, [rbx + REG_NAME]
        mov     ecx, [rbx + REG_NLEN]
        push    rax
        push    r8
        call    ieq_n
        pop     r8
        pop     rcx
        test    eax, eax
        jnz     .hit
        add     rbx, REG_SIZE
        inc     r8d
        mov     eax, ecx
        jmp     .loop
.hit:
        mov     eax, [rbx + REG_NUM]
        pop     r13
        pop     r12
        pop     rbx
        ret
.miss:
        mov     eax, -1
        pop     r13
        pop     r12
        pop     rbx
        ret
