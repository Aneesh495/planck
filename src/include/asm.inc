%ifndef PLANCK_ASM_INC
%define PLANCK_ASM_INC

TOK_EOF             equ 0
TOK_IDENT           equ 1
TOK_INT             equ 2
TOK_STR             equ 3
TOK_CHAR            equ 4
TOK_COMMA           equ 5
TOK_LPAREN          equ 6
TOK_RPAREN          equ 7
TOK_COLON           equ 8
TOK_NL              equ 9
TOK_DOT             equ 10
TOK_PLUS            equ 11
TOK_MINUS           equ 12
TOK_ERROR           equ 13

RELOC_B             equ 1
RELOC_J             equ 2
RELOC_HI20          equ 3
RELOC_LO12I         equ 4
RELOC_LO12S         equ 5
RELOC_ABS32         equ 6
RELOC_HI20_PC       equ 7                 ; AUIPC-relative

; lexer state
LEX_SRC             equ 0
LEX_LEN             equ 8
LEX_POS             equ 16
LEX_LINE            equ 20
LEX_COL             equ 24
LEX_TOK             equ 28
LEX_IVAL            equ 32
LEX_SVAL            equ 40
LEX_SLEN            equ 48
LEX_PATH            equ 56
LEX_SIZE            equ 64

; assembler
ASM_LEX             equ 0
ASM_SYMS            equ 8
ASM_EQUS            equ 16
ASM_BUF             equ 24
ASM_CAP             equ 32
ASM_LC              equ 36                ; location counter (guest addr)
ASM_START           equ 40
ASM_RELOCS          equ 48
ASM_NRELOC          equ 56
ASM_RELOC_CAP       equ 60
ASM_ERR             equ 64
ASM_ERRMSG          equ 72
ASM_CPU             equ 80
ASM_SIZE            equ 96

; reloc entry 32 bytes
REL_KIND            equ 0
REL_OFF             equ 4                 ; offset in image
REL_PC              equ 8
REL_SYM             equ 16                ; ptr to name, or 0 if ival already
REL_SLEN            equ 24
REL_ADDEND          equ 28
REL_SIZE            equ 32

MAX_IDENT           equ 64
MAX_RELOCS          equ 4096
MAX_ERR             equ 256

%endif
