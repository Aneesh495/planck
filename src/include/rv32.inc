%ifndef PLANCK_RV32_INC
%define PLANCK_RV32_INC

; RV32IM encodings and the internal opcode id space.
; Decoder and assembler both include this file. Do not drift.

; ---- opcodes (inst[6:0]) ------------------------------------------------
OPC_LOAD        equ 0x03
OPC_MISC_MEM    equ 0x0f
OPC_OP_IMM      equ 0x13
OPC_AUIPC       equ 0x17
OPC_STORE       equ 0x23
OPC_OP          equ 0x33
OPC_LUI         equ 0x37
OPC_BRANCH      equ 0x63
OPC_JALR        equ 0x67
OPC_JAL         equ 0x6f
OPC_SYSTEM      equ 0x73

; ---- funct3 -------------------------------------------------------------
F3_BEQ          equ 0
F3_BNE          equ 1
F3_BLT          equ 4
F3_BGE          equ 5
F3_BLTU         equ 6
F3_BGEU         equ 7

F3_LB           equ 0
F3_LH           equ 1
F3_LW           equ 2
F3_LBU          equ 4
F3_LHU          equ 5

F3_SB           equ 0
F3_SH           equ 1
F3_SW           equ 2

F3_ADDI         equ 0
F3_SLLI         equ 1
F3_SLTI         equ 2
F3_SLTIU        equ 3
F3_XORI         equ 4
F3_SRLI         equ 5
F3_SRAI         equ 5
F3_ORI          equ 6
F3_ANDI         equ 7

F3_ADD          equ 0
F3_SLL          equ 1
F3_SLT          equ 2
F3_SLTU         equ 3
F3_XOR          equ 4
F3_SRL          equ 5
F3_OR           equ 6
F3_AND          equ 7

F3_MUL          equ 0
F3_MULH         equ 1
F3_MULHSU       equ 2
F3_MULHU        equ 3
F3_DIV          equ 4
F3_DIVU         equ 5
F3_REM          equ 6
F3_REMU         equ 7

F3_FENCE        equ 0
F3_CSRRW        equ 1
F3_CSRRS        equ 2
F3_CSRRC        equ 3
F3_CSRRWI       equ 5
F3_CSRRSI       equ 6
F3_CSRRCI       equ 7
F3_PRIV         equ 0

; ---- funct7 -------------------------------------------------------------
F7_ADD          equ 0x00
F7_SUB          equ 0x20
F7_SRA          equ 0x20
F7_MUL          equ 0x01
F7_MRET         equ 0x18

; ---- internal ids: jump-table indices -----------------------------------
ID_ILLEGAL      equ 0
ID_LUI          equ 1
ID_AUIPC        equ 2
ID_JAL          equ 3
ID_JALR         equ 4
ID_BEQ          equ 5
ID_BNE          equ 6
ID_BLT          equ 7
ID_BGE          equ 8
ID_BLTU         equ 9
ID_BGEU         equ 10
ID_LB           equ 11
ID_LH           equ 12
ID_LW           equ 13
ID_LBU          equ 14
ID_LHU          equ 15
ID_SB           equ 16
ID_SH           equ 17
ID_SW           equ 18
ID_ADDI         equ 19
ID_SLTI         equ 20
ID_SLTIU        equ 21
ID_XORI         equ 22
ID_ORI          equ 23
ID_ANDI         equ 24
ID_SLLI         equ 25
ID_SRLI         equ 26
ID_SRAI         equ 27
ID_ADD          equ 28
ID_SUB          equ 29
ID_SLL          equ 30
ID_SLT          equ 31
ID_SLTU         equ 32
ID_XOR          equ 33
ID_SRL          equ 34
ID_SRA          equ 35
ID_OR           equ 36
ID_AND          equ 37
ID_FENCE        equ 38
ID_ECALL        equ 39
ID_EBREAK       equ 40
ID_CSRRW        equ 41
ID_CSRRS        equ 42
ID_CSRRC        equ 43
ID_CSRRWI       equ 44
ID_CSRRSI       equ 45
ID_CSRRCI       equ 46
ID_MUL          equ 47
ID_MULH         equ 48
ID_MULHSU       equ 49
ID_MULHU        equ 50
ID_DIV          equ 51
ID_DIVU         equ 52
ID_REM          equ 53
ID_REMU         equ 54
ID_MRET         equ 55
ID_COUNT        equ 56

; ---- exception causes ---------------------------------------------------
CAUSE_MISALIGNED_FETCH  equ 0
CAUSE_FETCH_ACCESS      equ 1
CAUSE_ILLEGAL_INST      equ 2
CAUSE_BREAKPOINT        equ 3
CAUSE_MISALIGNED_LOAD   equ 4
CAUSE_LOAD_ACCESS       equ 5
CAUSE_MISALIGNED_STORE  equ 6
CAUSE_STORE_ACCESS      equ 7
CAUSE_ECALL_M           equ 11

; ---- CSRs ---------------------------------------------------------------
CSR_MSTATUS     equ 0x300
CSR_MIE         equ 0x304
CSR_MTVEC       equ 0x305
CSR_MSCRATCH    equ 0x340
CSR_MEPC        equ 0x341
CSR_MCAUSE      equ 0x342
CSR_MTVAL       equ 0x343
CSR_MIP         equ 0x344
CSR_MCYCLE      equ 0xB00
CSR_MINSTRET    equ 0xB02
CSR_MCYCLEH     equ 0xB80
CSR_MINSTRETH   equ 0xB82
CSR_CYCLE       equ 0xC00
CSR_INSTRET     equ 0xC02
CSR_CYCLEH      equ 0xC80
CSR_INSTRETH    equ 0xC82
CSR_MVENDORID   equ 0xF11
CSR_MARCHID     equ 0xF12
CSR_MIMPID      equ 0xF13
CSR_MHARTID     equ 0xF14

MSTATUS_MIE     equ (1 << 3)
MSTATUS_MPIE    equ (1 << 7)
MSTATUS_MPP     equ (3 << 11)
MSTATUS_MPP_M   equ (3 << 11)

MIMPID_PLNK     equ 0x504C4E4B

; ---- decoded instruction ------------------------------------------------
DEC_RAW         equ 0
DEC_PC          equ 4
DEC_ID          equ 8
DEC_RD          equ 12
DEC_RS1         equ 16
DEC_RS2         equ 20
DEC_IMM         equ 24
DEC_CSR         equ 28
DEC_PRED_TAKEN  equ 32
DEC_PRED_NPC    equ 36
DEC_SIZE        equ 40
DEC_ILLEGAL     equ 44
DEC_SIZEOF      equ 48

; ---- ecall services -----------------------------------------------------
ECALL_EXIT      equ 0
ECALL_WRITE     equ 1
ECALL_READ      equ 2
ECALL_CYCLE     equ 3
ECALL_SBRK      equ 4
ECALL_DUMP      equ 5
ECALL_EXIT93    equ 93

; Bitfield extract helpers as constants for shifts.
INST_OPC_MASK   equ 0x7F
INST_RD_SHIFT   equ 7
INST_RD_MASK    equ 0x1F
INST_F3_SHIFT   equ 12
INST_F3_MASK    equ 0x7
INST_RS1_SHIFT  equ 15
INST_RS1_MASK   equ 0x1F
INST_RS2_SHIFT  equ 20
INST_RS2_MASK   equ 0x1F
INST_F7_SHIFT   equ 25
INST_F7_MASK    equ 0x7F
INST_CSR_SHIFT  equ 20
INST_CSR_MASK   equ 0xFFF
INST_IIMM_SHIFT equ 20

%endif
