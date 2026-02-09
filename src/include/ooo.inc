%ifndef PLANCK_OOO_INC
%define PLANCK_OOO_INC

FETCH_WIDTH         equ 2
DECODE_WIDTH        equ 2
ISSUE_WIDTH         equ 2
COMMIT_WIDTH        equ 2

ROB_CAP             equ 64
PRF_CAP             equ 96
PREG_ZERO           equ 0

RS_ALU_N            equ 8
RS_BR_N             equ 4
RS_MUL_N            equ 2
RS_DIV_N            equ 1
RS_LD_N             equ 8
RS_ST_N             equ 8
RS_TOTAL            equ (RS_ALU_N+RS_BR_N+RS_MUL_N+RS_DIV_N+RS_LD_N+RS_ST_N)

SB_CAP              equ 16
LQ_CAP              equ 16
FQ_CAP              equ 8                 ; fetch queue of decoded-or-raw insns

LAT_ALU             equ 1
LAT_BR              equ 1
LAT_MUL             equ 3
LAT_DIV             equ 16
LAT_LD_L1           equ 3
LAT_FORWARD         equ 1

FU_ALU              equ 0
FU_BR               equ 1
FU_MUL              equ 2
FU_DIV              equ 3
FU_LD               equ 4
FU_ST               equ 5
FU_COUNT            equ 6

RS_CLASS_ALU        equ 0
RS_CLASS_BR         equ 1
RS_CLASS_MUL        equ 2
RS_CLASS_DIV        equ 3
RS_CLASS_LD         equ 4
RS_CLASS_ST         equ 5

; ROB entry 64 bytes — docs/LAYOUT.md
ROB_VALID           equ 0
ROB_COMPLETE        equ 4
ROB_RD              equ 8
ROB_DST             equ 12
ROB_OLD             equ 16
ROB_PC              equ 20
ROB_NPC             equ 24
ROB_PRED_NPC        equ 28
ROB_VAL             equ 32
ROB_ID              equ 36
ROB_EXC             equ 40
ROB_CAUSE           equ 44
ROB_IS_ST           equ 48
ROB_IS_BR           equ 52
ROB_MISPRED         equ 56
ROB_RAS_TOS         equ 60
ROB_ENT_SIZE        equ 64

; RS entry 64 bytes
RS_VALID            equ 0
RS_ROB              equ 4
RS_OP               equ 8
RS_DST              equ 12
RS_S1               equ 16
RS_S1_TAG           equ 20
RS_S1_RDY           equ 24
RS_S2               equ 28
RS_S2_TAG           equ 32
RS_S2_RDY           equ 36
RS_IMM              equ 40
RS_PC               equ 44
RS_PRED_NPC         equ 48
RS_FU_LAT           equ 52
RS_ISSUED           equ 56
RS_CLASS            equ 60
RS_ENT_SIZE         equ 64

; FU pipe slot
FU_BUSY             equ 0
FU_REM              equ 4
FU_ROB              equ 8
FU_DST              equ 12
FU_VAL              equ 16
FU_NPC              equ 20
FU_MISPRED          equ 24
FU_EXC              equ 28
FU_CAUSE            equ 32
FU_OP               equ 36
FU_SLOT_SIZE        equ 48
FU_ALU_PIPES        equ 2

; Store buffer entry
SB_VALID            equ 0
SB_ROB              equ 4
SB_ADDR             equ 8
SB_ADDR_RDY         equ 12
SB_DATA             equ 16
SB_DATA_RDY         equ 20
SB_SIZE             equ 24                ; 1,2,4
SB_COMMITTED        equ 28
SB_ENT_SIZE         equ 32

; Load queue
LQ_VALID            equ 0
LQ_ROB              equ 4
LQ_ADDR             equ 8
LQ_SIZE             equ 12
LQ_ISSUED           equ 16
LQ_DONE             equ 20
LQ_ENT_SIZE         equ 24

; Fetch queue raw insn
FQ_VALID            equ 0
FQ_INST             equ 4
FQ_PC               equ 8
FQ_PRED_TAKEN       equ 12
FQ_PRED_NPC         equ 16
FQ_ENT_SIZE         equ 24

; Physical RF
PRF_VAL             equ 0                 ; array of 96 dwords, then valid bytes
; layout in ooo_t: see below

; ooo_t header
OOO_HEAD            equ 0                 ; ROB head
OOO_TAIL            equ 4
OOO_COUNT           equ 8
OOO_FL_HEAD         equ 12
OOO_FL_TAIL         equ 16
OOO_FL_COUNT        equ 20
OOO_FQ_HEAD         equ 24
OOO_FQ_TAIL         equ 28
OOO_FQ_COUNT        equ 32
OOO_SB_HEAD         equ 36
OOO_SB_COUNT        equ 40
OOO_LQ_COUNT        equ 44
OOO_MAP_S           equ 48                ; ptr int32[32]
OOO_MAP_A           equ 56
OOO_FREELIST        equ 64                ; ptr int32[PRF_CAP]
OOO_PRF_VAL         equ 72                ; ptr int32[PRF_CAP]
OOO_PRF_VLD         equ 80                ; ptr uint8[PRF_CAP]
OOO_ROB             equ 88
OOO_RS              equ 96                ; all RS packed: ALU|BR|MUL|DIV|LD|ST
OOO_FU              equ 104
OOO_SB              equ 112
OOO_LQ              equ 120
OOO_FQ              equ 128
OOO_RS_USED         equ 136               ; 6 dwords of occupancy
OOO_SIZE            equ 256               ; header; arrays are separate arena ptrs

RS_ALU_OFF          equ 0
RS_BR_OFF           equ (RS_ALU_N * RS_ENT_SIZE)
RS_MUL_OFF          equ (RS_BR_OFF + RS_BR_N * RS_ENT_SIZE)
RS_DIV_OFF          equ (RS_MUL_OFF + RS_MUL_N * RS_ENT_SIZE)
RS_LD_OFF           equ (RS_DIV_OFF + RS_DIV_N * RS_ENT_SIZE)
RS_ST_OFF           equ (RS_LD_OFF + RS_LD_N * RS_ENT_SIZE)

%endif
