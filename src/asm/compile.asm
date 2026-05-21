; src/asm/compile.asm
; Two-pass assembler driver plus instruction/directive parsing.

        bits 64
        default rel

%include "macros.inc"
%include "asm.inc"
%include "abi.inc"
%include "hash.inc"
%include "rv32.inc"
%include "cpu.inc"

        extern lex_init
        extern lex_next
        extern mnem_lookup
        extern reg_lookup
        extern hash_init
        extern hash_put
        extern hash_get
        extern arena_alloc
        extern pack_r
        extern pack_i
        extern pack_s
        extern pack_b
        extern pack_u
        extern pack_j
        extern lui_hi
        extern fits_i12
        extern fits_b13
        extern fits_j21
        extern host_die
        extern mem_cpy
        extern io_cstr
        extern io_nl
        extern io_dec
        extern str_eq_n

        section .rodata
err_tok:        db "unexpected token",0
err_mnem:       db "unknown mnemonic",0
err_reg:        db "expected register",0
err_imm:        db "expected immediate",0
err_sym:        db "undefined symbol",0
err_dup:        db "duplicate label",0
err_range:      db "immediate out of range",0
err_dir:        db "unknown directive",0
err_comma:      db "expected comma",0
err_lpar:       db "expected '('",0
err_rpar:       db "expected ')'",0

        section .bss
        align 16
mnem_rec:       resb MNEM_SIZE
asm_st:         resb ASM_SIZE
lex_st:         resb LEX_SIZE
hash_syms:      resb HM_SIZE
hash_equs:      resb HM_SIZE
look_tok:       resd 1
look_ival:      resd 1
look_slen:      resd 1
look_sval:      resq 1
have_look:      resd 1
cur_pass:       resd 1
img_buf:        resq 1
img_cap:        resd 1

        section .text

tok:
        lea     rax, [rel lex_st]
        ret

; consume token into look_* if have_look else lex_next
next_tok:
        cmp     dword [rel have_look], 0
        je      .lex
        mov     dword [rel have_look], 0
        lea     rdi, [rel lex_st]
        mov     eax, [rel look_tok]
        mov     [rdi + LEX_TOK], eax
        mov     eax, [rel look_ival]
        mov     [rdi + LEX_IVAL], eax
        mov     eax, [rel look_slen]
        mov     [rdi + LEX_SLEN], eax
        mov     rax, [rel look_sval]
        mov     [rdi + LEX_SVAL], rax
        mov     eax, [rdi + LEX_TOK]
        ret
.lex:
        lea     rdi, [rel lex_st]
        call    lex_next
        ret

unget_tok:
        lea     rdi, [rel lex_st]
        mov     eax, [rdi + LEX_TOK]
        mov     [rel look_tok], eax
        mov     eax, [rdi + LEX_IVAL]
        mov     [rel look_ival], eax
        mov     eax, [rdi + LEX_SLEN]
        mov     [rel look_slen], eax
        mov     rax, [rdi + LEX_SVAL]
        mov     [rel look_sval], rax
        mov     dword [rel have_look], 1
        ret

cur_tok:
        lea     rax, [rel lex_st]
        mov     eax, [rax + LEX_TOK]
        ret

; void asm_fail(const char *msg)
asm_fail:
        push    rdi
        mov     edi, 2
        extern io_cstr
        lea     rsi, [rel fail_pre]
        call    io_cstr
        pop     rsi
        mov     edi, 2
        call    io_cstr
        mov     edi, 2
        call    io_nl
        ; line number
        mov     edi, 2
        lea     rsi, [rel fail_line]
        call    io_cstr
        mov     edi, 2
        lea     rax, [rel lex_st]
        mov     esi, [rax + LEX_LINE]
        xor     edx, edx
        mov     ecx, 10
        extern io_udec
        call    io_udec
        mov     edi, 2
        call    io_nl
        lea     rdi, [rel err_tok]
        ; use host_die with the original msg still... just die
        pop     rax                     ; alignment
        ; we already printed. exit 1
        extern host_exit
        mov     edi, 1
        call    host_exit
        ret

        section .rodata
fail_pre:       db "planck asm: ",0
fail_line:      db "  line ",0

        section .text

expect:
        ; edi = token kind
        push    rdi
        call    next_tok
        pop     rdi
        cmp     eax, edi
        je      .ok
        lea     rdi, [rel err_tok]
        call    asm_fail
.ok:
        ret

; int parse_reg(void) → 0..31 or fail
parse_reg:
        call    next_tok
        cmp     eax, TOK_IDENT
        je      .id
        lea     rdi, [rel err_reg]
        call    asm_fail
.id:
        lea     rax, [rel lex_st]
        mov     rdi, [rax + LEX_SVAL]
        mov     esi, [rax + LEX_SLEN]
        call    reg_lookup
        cmp     eax, 0
        js      .bad
        ret
.bad:
        lea     rdi, [rel err_reg]
        call    asm_fail
        ret

; int parse_imm(void)  — integer, char, or symbol (pass2)
parse_imm:
        call    next_tok
        cmp     eax, TOK_INT
        je      .int
        cmp     eax, TOK_CHAR
        je      .int
        cmp     eax, TOK_MINUS
        je      .neg
        cmp     eax, TOK_IDENT
        je      resolve_sym
        lea     rdi, [rel err_imm]
        call    asm_fail
.int:
        lea     rax, [rel lex_st]
        mov     eax, [rax + LEX_IVAL]
        ret
.neg:
        call    next_tok
        cmp     eax, TOK_INT
        jne     .bad
        lea     rax, [rel lex_st]
        mov     eax, [rax + LEX_IVAL]
        neg     eax
        ret
.bad:
        lea     rdi, [rel err_imm]
        call    asm_fail
        ret

resolve_sym:
        ; uses lex sval/slen
        sub     rsp, 16
        lea     rax, [rel lex_st]
        mov     rsi, [rax + LEX_SVAL]
        mov     edx, [rax + LEX_SLEN]
        lea     rdi, [rel hash_equs]
        lea     rcx, [rsp]
        call    hash_get
        test    eax, eax
        jz      .hit
        lea     rax, [rel lex_st]
        mov     rsi, [rax + LEX_SVAL]
        mov     edx, [rax + LEX_SLEN]
        lea     rdi, [rel hash_syms]
        lea     rcx, [rsp]
        call    hash_get
        test    eax, eax
        jz      .hit
        cmp     dword [rel cur_pass], 1
        je      .zero
        lea     rdi, [rel err_sym]
        call    asm_fail
.zero:
        xor     eax, eax
        add     rsp, 16
        ret
.hit:
        mov     eax, [rsp]
        add     rsp, 16
        ret

emit_u8:
        ; edi = byte, LC in asm_st
        lea     rcx, [rel asm_st]
        mov     edx, [rcx + ASM_LC]
        sub     edx, GUEST_RESET
        cmp     edx, MAX_SOURCE_BYTES
        jae     .oob
        cmp     dword [rel cur_pass], 2
        jne     .bump
        mov     rax, [rel img_buf]
        mov     [rax + rdx], dil
.bump:
        lea     rcx, [rel asm_st]
        inc     dword [rcx + ASM_LC]
        ret
.oob:
        lea     rdi, [rel err_range]
        call    asm_fail
        ret

emit_u16:
        push    rdi
        call    emit_u8
        pop     rdi
        shr     edi, 8
        jmp     emit_u8

emit_u32:
        push    rdi
        call    emit_u8
        pop     rdi
        push    rdi
        shr     edi, 8
        call    emit_u8
        pop     rdi
        push    rdi
        shr     edi, 16
        call    emit_u8
        pop     rdi
        shr     edi, 24
        jmp     emit_u8

skip_nl:
.loop:
        call    next_tok
        cmp     eax, TOK_NL
        je      .loop
        cmp     eax, TOK_EOF
        je      .out
        call    unget_tok
.out:
        ret

define_label:
        ; sval/slen currently the ident, LC is value
        cmp     dword [rel cur_pass], 1
        jne     .p2
        lea     rax, [rel lex_st]
        ; we ungot? caller has name in look or current
        ; use look if have... pass name in r12/r13d from caller
        lea     rdi, [rel hash_syms]
        mov     rsi, r12
        mov     edx, r13d
        lea     rcx, [rel asm_st]
        mov     ecx, [rcx + ASM_LC]
        mov     ecx, ecx
        ; hash_put rdi rsi rdx rcx=val
        mov     ecx, ecx
        lea     rax, [rel asm_st]
        mov     ecx, [rax + ASM_LC]
        call    hash_put
        ret
.p2:
        ret

; ---- directives ---------------------------------------------------------

dir_byte:
.loop:
        call    parse_imm
        mov     edi, eax
        call    emit_u8
        call    next_tok
        cmp     eax, TOK_COMMA
        je      .loop
        call    unget_tok
        ret

dir_half:
.loop:
        call    parse_imm
        mov     edi, eax
        call    emit_u16
        call    next_tok
        cmp     eax, TOK_COMMA
        je      .loop
        call    unget_tok
        ret

dir_word:
.loop:
        call    parse_imm
        mov     edi, eax
        call    emit_u32
        call    next_tok
        cmp     eax, TOK_COMMA
        je      .loop
        call    unget_tok
        ret

dir_space:
        call    parse_imm
        mov     r8d, eax
        test    r8d, r8d
        jle     .out
.z:
        xor     edi, edi
        push    r8
        call    emit_u8
        pop     r8
        dec     r8d
        jnz     .z
.out:
        ret

dir_align:
        call    parse_imm
        mov     ecx, eax
        cmp     ecx, 8
        ja      .bad
        mov     eax, 1
        shl     eax, cl
        ; align LC up
        lea     rdx, [rel asm_st]
        mov     edi, [rdx + ASM_LC]
        mov     esi, eax
        dec     esi
        add     edi, esi
        not     esi
        and     edi, esi
        ; emit zeros until LC == edi
        mov     r8d, edi
.pad:
        lea     rdx, [rel asm_st]
        cmp     [rdx + ASM_LC], r8d
        jae     .out
        xor     edi, edi
        push    r8
        call    emit_u8
        pop     r8
        jmp     .pad
.out:
        ret
.bad:
        lea     rdi, [rel err_range]
        call    asm_fail
        ret

dir_org:
        call    parse_imm
        lea     rdx, [rel asm_st]
        cmp     eax, [rdx + ASM_LC]
        jb      .bad
        mov     r8d, eax
        jmp     dir_align.pad
.bad:
        lea     rdi, [rel err_range]
        call    asm_fail
        ret

dir_ascii:
        call    next_tok
        cmp     eax, TOK_STR
        jne     .bad
        lea     rax, [rel lex_st]
        mov     r12, [rax + LEX_SVAL]
        mov     r13d, [rax + LEX_SLEN]
        xor     r14d, r14d
.loop:
        cmp     r14d, r13d
        jge     .out
        movzx   edi, byte [r12 + r14]
        cmp     edi, '\'
        jne     .em
        inc     r14d
        movzx   edi, byte [r12 + r14]
        ; naive: emit the escaped byte as-is for n,t
        cmp     edi, 'n'
        jne     .e1
        mov     edi, 10
        jmp     .em
.e1:    cmp     edi, 't'
        jne     .em
        mov     edi, 9
.em:
        push    r12
        push    r13
        push    r14
        call    emit_u8
        pop     r14
        pop     r13
        pop     r12
        inc     r14d
        jmp     .loop
.out:
        ret
.bad:
        lea     rdi, [rel err_tok]
        call    asm_fail
        ret

dir_asciiz:
        call    dir_ascii
        xor     edi, edi
        jmp     emit_u8

dir_equ:
        call    next_tok
        cmp     eax, TOK_IDENT
        jne     .bad
        lea     rax, [rel lex_st]
        mov     r12, [rax + LEX_SVAL]
        mov     r13d, [rax + LEX_SLEN]
        mov     edi, TOK_COMMA
        call    expect
        call    parse_imm
        cmp     dword [rel cur_pass], 1
        jne     .out
        lea     rdi, [rel hash_equs]
        mov     rsi, r12
        mov     edx, r13d
        mov     ecx, eax
        call    hash_put
.out:
        ret
.bad:
        lea     rdi, [rel err_tok]
        call    asm_fail
        ret

dir_globl:
        call    next_tok                ; eat ident
        ret

dir_text:
        ret
dir_data:
        ret

; ---- instructions -------------------------------------------------------

need_comma:
        mov     edi, TOK_COMMA
        jmp     expect

; parse mem: imm(reg) or (reg)
parse_mem:
        ; returns imm in eax, rs1 in r15d
        call    next_tok
        cmp     eax, TOK_LPAREN
        je      .noregimm
        call    unget_tok
        call    parse_imm
        mov     r14d, eax
        mov     edi, TOK_LPAREN
        call    expect
        call    parse_reg
        mov     r15d, eax
        mov     edi, TOK_RPAREN
        call    expect
        mov     eax, r14d
        ret
.noregimm:
        xor     r14d, r14d
        call    parse_reg
        mov     r15d, eax
        mov     edi, TOK_RPAREN
        call    expect
        xor     eax, eax
        ret

emit_r:
        ; rd r8d, rs1 r9d, rs2 r10d, use mnem_rec
        mov     edi, r8d
        mov     esi, r9d
        mov     edx, r10d
        lea     rax, [rel mnem_rec]
        mov     ecx, [rax + MNEM_F3]
        mov     r8d, [rax + MNEM_F7]
        mov     r9d, [rax + MNEM_OPC]
        call    pack_r
        mov     edi, eax
        jmp     emit_u32

; parse and emit based on form in mnem_rec
parse_inst:
        lea     rax, [rel mnem_rec]
        mov     eax, [rax + MNEM_FORM]
        cmp     eax, FORM_PSEUDO
        je      parse_pseudo
        cmp     eax, FORM_NONE
        je      .none
        cmp     eax, FORM_R
        je      .r
        cmp     eax, FORM_I
        je      .i
        cmp     eax, FORM_ISH
        je      .ish
        cmp     eax, FORM_S
        je      .s
        cmp     eax, FORM_B
        je      .b
        cmp     eax, FORM_U
        je      .u
        cmp     eax, FORM_J
        je      .j
        cmp     eax, FORM_LOAD
        je      .load
        cmp     eax, FORM_CSR
        je      .csr
        lea     rdi, [rel err_mnem]
        call    asm_fail
        ret

.none:
        lea     rax, [rel mnem_rec]
        mov     eax, [rax + MNEM_ID]
        cmp     eax, ID_ECALL
        je      .ecall
        cmp     eax, ID_EBREAK
        je      .ebreak
        cmp     eax, ID_MRET
        je      .mret
        cmp     eax, ID_FENCE
        je      .fence
        ret
.ecall:
        mov     edi, 0x00000073
        jmp     emit_u32
.ebreak:
        mov     edi, 0x00100073
        jmp     emit_u32
.mret:
        mov     edi, 0x30200073
        jmp     emit_u32
.fence:
        mov     edi, 0x0FF0000F         ; fence iorw, iorw
        jmp     emit_u32

.r:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_reg
        mov     r9d, eax
        call    need_comma
        call    parse_reg
        mov     r10d, eax
        jmp     emit_r

.i:
        call    parse_reg
        mov     r8d, eax                ; rd
        call    need_comma
        call    parse_reg
        mov     r9d, eax                ; rs1
        call    need_comma
        call    parse_imm
        mov     r10d, eax               ; imm
        ; pack_i rd, rs1, imm, f3, opc
        mov     edi, r8d
        mov     esi, r9d
        mov     edx, r10d
        lea     rax, [rel mnem_rec]
        mov     ecx, [rax + MNEM_F3]
        mov     r8d, [rax + MNEM_OPC]
        call    pack_i
        mov     edi, eax
        jmp     emit_u32

.ish:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_reg
        mov     r9d, eax
        call    need_comma
        call    parse_imm
        and     eax, 31
        ; I-type with f7 in high of imm
        lea     rcx, [rel mnem_rec]
        mov     edx, [rcx + MNEM_F7]
        shl     edx, 5
        or      edx, eax                ; imm[11:0] = f7|shamt
        mov     edi, r8d
        mov     esi, r9d
        mov     ecx, [rcx + MNEM_F3]
        mov     r8d, [rcx + MNEM_OPC]
        call    pack_i
        mov     edi, eax
        jmp     emit_u32

.s:
        call    parse_reg
        mov     r10d, eax               ; rs2
        call    need_comma
        call    parse_mem               ; imm eax, rs1 r15d
        mov     r9d, r15d
        mov     r8d, eax                ; imm
        ; pack_s rs1, rs2, imm, f3, opc
        mov     edi, r9d
        mov     esi, r10d
        mov     edx, r8d
        lea     rax, [rel mnem_rec]
        mov     ecx, [rax + MNEM_F3]
        mov     r8d, [rax + MNEM_OPC]
        call    pack_s
        mov     edi, eax
        jmp     emit_u32

.b:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_reg
        mov     r9d, eax
        call    need_comma
        call    parse_imm               ; target address or offset? we take symbol as abs addr
        ; offset = target - pc
        lea     rcx, [rel asm_st]
        mov     edx, [rcx + ASM_LC]
        sub     eax, edx
        mov     r10d, eax
        cmp     dword [rel cur_pass], 1
        je      .bemit
        mov     edi, r10d
        call    fits_b13
        test    eax, eax
        jnz     .bemit
        lea     rdi, [rel err_range]
        call    asm_fail
.bemit:
        mov     edi, r8d
        mov     esi, r9d
        mov     edx, r10d
        lea     rax, [rel mnem_rec]
        mov     ecx, [rax + MNEM_F3]
        mov     r8d, [rax + MNEM_OPC]
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

.u:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        shl     eax, 12                 ; 20-bit field → bits 31:12
        mov     esi, eax
        mov     edi, r8d
        lea     rax, [rel mnem_rec]
        mov     edx, [rax + MNEM_OPC]
        call    pack_u
        mov     edi, eax
        jmp     emit_u32

.j:
        ; jal rd, target  OR we always parsed rd
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        mov     edx, [rcx + ASM_LC]
        sub     eax, edx
        mov     r10d, eax
        cmp     dword [rel cur_pass], 1
        je      .jem
        mov     edi, r10d
        call    fits_j21
        test    eax, eax
        jnz     .jem
        lea     rdi, [rel err_range]
        call    asm_fail
.jem:
        mov     edi, r8d
        mov     esi, r10d
        lea     rax, [rel mnem_rec]
        mov     edx, [rax + MNEM_OPC]
        call    pack_j
        mov     edi, eax
        jmp     emit_u32

.load:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_mem
        mov     r10d, eax               ; imm
        mov     r9d, r15d
        mov     edi, r8d
        mov     esi, r9d
        mov     edx, r10d
        lea     rax, [rel mnem_rec]
        mov     ecx, [rax + MNEM_F3]
        mov     r8d, [rax + MNEM_OPC]
        call    pack_i
        mov     edi, eax
        jmp     emit_u32

.csr:
        call    parse_reg
        mov     r8d, eax                ; rd
        call    need_comma
        call    parse_imm               ; csr number
        mov     r10d, eax
        call    need_comma
        ; rs1 or zimm: register or int
        call    next_tok
        cmp     eax, TOK_INT
        je      .csrimm
        call    unget_tok
        call    parse_reg
        mov     r9d, eax
        jmp     .csrp
.csrimm:
        lea     rax, [rel lex_st]
        mov     r9d, [rax + LEX_IVAL]
.csrp:
        ; pack_i rd, rs1, csr_imm, f3, opc
        mov     edi, r8d
        mov     esi, r9d
        mov     edx, r10d
        lea     rax, [rel mnem_rec]
        mov     ecx, [rax + MNEM_F3]
        mov     r8d, [rax + MNEM_OPC]
        call    pack_i
        mov     edi, eax
        jmp     emit_u32

; ---- pseudos ------------------------------------------------------------

parse_pseudo:
        lea     rax, [rel mnem_rec]
        mov     rsi, [rax + MNEM_NAME]
        mov     edx, [rax + MNEM_NLEN]
        ; compare to known names — dispatch by first letter + len
        jmp     pseudo_dispatch

pseudo_dispatch:
        ; r12 = name ptr, r13 = nlen from mnem_rec
        lea     rax, [rel mnem_rec]
        mov     r12, [rax + MNEM_NAME]
        mov     r13d, [rax + MNEM_NLEN]
        lea     rdi, [rel ncmp_nop]
        mov     esi, 3
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_nop
        lea     rdi, [rel ncmp_li]
        mov     esi, 2
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_li
        lea     rdi, [rel ncmp_mv]
        mov     esi, 2
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_mv
        lea     rdi, [rel ncmp_j]
        mov     esi, 1
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_j
        lea     rdi, [rel ncmp_jal]
        ; jal as pseudo 1-operand is in tables as real jal FORM_J — 2-operand required.
        lea     rdi, [rel ncmp_jr]
        mov     esi, 2
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_jr
        lea     rdi, [rel ncmp_ret]
        mov     esi, 3
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_ret
        lea     rdi, [rel ncmp_not]
        mov     esi, 3
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_not
        lea     rdi, [rel ncmp_neg]
        mov     esi, 3
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_neg
        lea     rdi, [rel ncmp_beqz]
        mov     esi, 4
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_beqz
        lea     rdi, [rel ncmp_bnez]
        mov     esi, 4
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_bnez
        lea     rdi, [rel ncmp_ble]
        mov     esi, 3
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_ble
        lea     rdi, [rel ncmp_bgt]
        mov     esi, 3
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_bgt
        lea     rdi, [rel ncmp_bltz]
        mov     esi, 4
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_bltz
        lea     rdi, [rel ncmp_bgez]
        mov     esi, 4
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_bgez
        lea     rdi, [rel ncmp_blez]
        mov     esi, 4
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_blez
        lea     rdi, [rel ncmp_bgtz]
        mov     esi, 4
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_bgtz
        lea     rdi, [rel ncmp_call]
        mov     esi, 4
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_call
        lea     rdi, [rel ncmp_la]
        mov     esi, 2
        mov     rdx, r12
        mov     ecx, r13d
        call    str_eq_n
        test    eax, eax
        jnz     ps_la
        lea     rdi, [rel err_mnem]
        call    asm_fail
        ret

        section .rodata
ncmp_nop:       db "nop"
ncmp_li:        db "li"
ncmp_mv:        db "mv"
ncmp_j:         db "j"
ncmp_jal:       db "jal"
ncmp_jr:        db "jr"
ncmp_ret:       db "ret"
ncmp_not:       db "not"
ncmp_neg:       db "neg"
ncmp_beqz:      db "beqz"
ncmp_bnez:      db "bnez"
ncmp_ble:       db "ble"
ncmp_bgt:       db "bgt"
ncmp_bltz:      db "bltz"
ncmp_bgez:      db "bgez"
ncmp_blez:      db "blez"
ncmp_bgtz:      db "bgtz"
ncmp_call:      db "call"
ncmp_la:        db "la"

        section .text

emit_i_fixed:
        ; edi=rd esi=rs1 edx=imm ecx=f3 r8d=opc
        call    pack_i
        mov     edi, eax
        jmp     emit_u32

ps_nop:
        xor     edi, edi
        xor     esi, esi
        xor     edx, edx
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        jmp     emit_i_fixed

ps_mv:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_reg
        mov     esi, eax
        mov     edi, r8d
        xor     edx, edx
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        jmp     emit_i_fixed

ps_not:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_reg
        mov     esi, eax
        mov     edi, r8d
        mov     edx, -1
        mov     ecx, F3_XORI
        mov     r8d, OPC_OP_IMM
        jmp     emit_i_fixed

ps_neg:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_reg
        ; sub rd, x0, rs
        mov     r10d, eax
        mov     edi, r8d
        xor     esi, esi
        mov     edx, r10d
        xor     ecx, ecx
        mov     r8d, F7_SUB
        mov     r9d, OPC_OP
        call    pack_r
        mov     edi, eax
        jmp     emit_u32

ps_jr:
        call    parse_reg
        mov     esi, eax
        xor     edi, edi
        xor     edx, edx
        xor     ecx, ecx
        mov     r8d, OPC_JALR
        jmp     emit_i_fixed

ps_ret:
        xor     edi, edi
        mov     esi, 1                  ; ra
        xor     edx, edx
        xor     ecx, ecx
        mov     r8d, OPC_JALR
        jmp     emit_i_fixed

ps_j:
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     esi, eax
        xor     edi, edi
        mov     edx, OPC_JAL
        call    pack_j
        mov     edi, eax
        jmp     emit_u32

ps_call:
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     esi, eax
        mov     edi, 1                  ; ra
        mov     edx, OPC_JAL
        call    pack_j
        mov     edi, eax
        jmp     emit_u32

ps_beqz:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     edi, r8d
        xor     esi, esi
        mov     edx, eax
        xor     ecx, ecx
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_bnez:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     edi, r8d
        xor     esi, esi
        mov     edx, eax
        mov     ecx, F3_BNE
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_bltz:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     edi, r8d
        xor     esi, esi
        mov     edx, eax
        mov     ecx, F3_BLT
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_bgez:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     edi, r8d
        xor     esi, esi
        mov     edx, eax
        mov     ecx, F3_BGE
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_blez:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        xor     edi, edi                ; rs1 = x0
        mov     esi, r8d                ; rs2 = rs
        mov     edx, eax
        mov     ecx, F3_BGE
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_bgtz:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        xor     edi, edi
        mov     esi, r8d
        mov     edx, eax
        mov     ecx, F3_BLT
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_ble:
        call    parse_reg
        mov     r8d, eax                ; a
        call    need_comma
        call    parse_reg
        mov     r9d, eax                ; b
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     edi, r9d                ; bge b, a
        mov     esi, r8d
        mov     edx, eax
        mov     ecx, F3_BGE
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_bgt:
        call    parse_reg
        mov     r8d, eax
        call    need_comma
        call    parse_reg
        mov     r9d, eax
        call    need_comma
        call    parse_imm
        lea     rcx, [rel asm_st]
        sub     eax, [rcx + ASM_LC]
        mov     edi, r9d                ; blt b, a
        mov     esi, r8d
        mov     edx, eax
        mov     ecx, F3_BLT
        mov     r8d, OPC_BRANCH
        call    pack_b
        mov     edi, eax
        jmp     emit_u32

ps_li:
        call    parse_reg
        mov     r12d, eax
        call    need_comma
        call    parse_imm
        mov     r13d, eax
        mov     edi, r13d
        call    fits_i12
        test    eax, eax
        jz      .wide
        mov     edi, r12d
        xor     esi, esi
        mov     edx, r13d
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        jmp     emit_i_fixed
.wide:
        mov     edi, r13d
        call    lui_hi
        shl     eax, 12                 ; pack_u wants imm already in [31:12]
        mov     esi, eax
        mov     edi, r12d
        mov     edx, OPC_LUI
        call    pack_u
        mov     edi, eax
        call    emit_u32
        ; lo
        mov     eax, r13d
        shl     eax, 20
        sar     eax, 20
        test    eax, eax
        jz      .done
        mov     edi, r12d
        mov     esi, r12d
        mov     edx, eax
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        jmp     emit_i_fixed
.done:
        ret

ps_la:
        ; auipc rd, hi ; addi rd, rd, lo  pc-relative
        call    parse_reg
        mov     r12d, eax
        call    need_comma
        call    parse_imm               ; abs address
        lea     rcx, [rel asm_st]
        mov     edx, [rcx + ASM_LC]
        sub     eax, edx                ; offset
        mov     r13d, eax
        mov     edi, r13d
        call    lui_hi                  ; actually hi of pc-rel: same as li
        shl     eax, 12
        mov     esi, eax
        mov     edi, r12d
        mov     edx, OPC_AUIPC
        call    pack_u
        mov     edi, eax
        call    emit_u32
        mov     eax, r13d
        shl     eax, 20
        sar     eax, 20
        mov     edi, r12d
        mov     esi, r12d
        mov     edx, eax
        xor     ecx, ecx
        mov     r8d, OPC_OP_IMM
        jmp     emit_i_fixed

; ---- statement / pass ---------------------------------------------------

parse_directive:
        ; current token is IDENT starting with? we consumed '.' as part of ident
        ; because is_ident_start accepts '.'
        lea     rax, [rel lex_st]
        mov     r12, [rax + LEX_SVAL]
        mov     r13d, [rax + LEX_SLEN]
        ; skip leading dot in compare
        mov     rdi, r12
        cmp     byte [rdi], '.'
        jne     .unk
        inc     rdi
        dec     r13d
        mov     r12, rdi
        lea     rsi, [rel d_byte]
        mov     edx, r13d
        ; helper: match
        jmp     dir_match
.unk:
        lea     rdi, [rel err_dir]
        call    asm_fail
        ret

dir_match:
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_byte]
        mov     ecx, 4
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_byte
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_half]
        mov     ecx, 4
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_half
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_word]
        mov     ecx, 4
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_word
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_space]
        mov     ecx, 5
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_space
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_align]
        mov     ecx, 5
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_align
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_org]
        mov     ecx, 3
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_org
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_ascii]
        mov     ecx, 5
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_ascii
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_asciiz]
        mov     ecx, 6
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_asciiz
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_equ]
        mov     ecx, 3
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_equ
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_globl]
        mov     ecx, 5
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_globl
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_global]
        mov     ecx, 6
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_globl
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_text]
        mov     ecx, 4
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_text
        push    r12
        push    r13
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel d_data]
        mov     ecx, 4
        call    str_eq_n
        pop     r13
        pop     r12
        test    eax, eax
        jnz     dir_data
        lea     rdi, [rel err_dir]
        call    asm_fail
        ret

        section .rodata
d_byte:         db "byte"
d_half:         db "half"
d_word:         db "word"
d_space:        db "space"
d_align:        db "align"
d_org:          db "org"
d_ascii:        db "ascii"
d_asciiz:       db "asciiz"
d_equ:          db "equ"
d_globl:        db "globl"
d_global:       db "global"
d_text:         db "text"
d_data:         db "data"

        section .text

parse_stmt:
        call    next_tok
        cmp     eax, TOK_EOF
        je      .eof
        cmp     eax, TOK_NL
        je      parse_stmt
        cmp     eax, TOK_IDENT
        jne     .bad
        ; save ident
        lea     rax, [rel lex_st]
        mov     r12, [rax + LEX_SVAL]
        mov     r13d, [rax + LEX_SLEN]
        cmp     byte [r12], '.'
        je      parse_directive
        call    next_tok
        cmp     eax, TOK_COLON
        je      .label
        call    unget_tok
        ; mnemonic
        mov     rdi, r12
        mov     esi, r13d
        lea     rdx, [rel mnem_rec]
        call    mnem_lookup
        test    eax, eax
        jnz     .badm
        call    parse_inst
        ret
.label:
        cmp     dword [rel cur_pass], 1
        jne     .ok
        lea     rdi, [rel hash_syms]
        mov     rsi, r12
        mov     edx, r13d
        lea     rax, [rel asm_st]
        mov     ecx, [rax + ASM_LC]
        call    hash_put
.ok:
        ret
.bad:
        lea     rdi, [rel err_tok]
        call    asm_fail
.badm:
        lea     rdi, [rel err_mnem]
        call    asm_fail
.eof:
        mov     eax, TOK_EOF
        ret

run_pass:
        mov     [rel cur_pass], edi
        mov     dword [rel have_look], 0
        lea     rcx, [rel asm_st]
        mov     eax, GUEST_RESET
        mov     [rcx + ASM_LC], eax
        lea     rdi, [rel lex_st]
        xor     eax, eax
        mov     [rdi + LEX_POS], eax
        mov     dword [rdi + LEX_LINE], 1
        mov     dword [rdi + LEX_COL], 1
.loop:
        call    next_tok
        cmp     eax, TOK_EOF
        je      .done
        cmp     eax, TOK_NL
        je      .loop
        call    unget_tok
        call    parse_stmt
        jmp     .loop
.done:
        ret

; int asm_compile(src, len, path, void **out, uint64 *outlen)
        global asm_compile
PROC asm_compile
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     r12, rdi                ; src
        mov     r13, rsi                ; len
        mov     r14, rcx                ; **out
        mov     r15, r8                 ; *outlen
        ; path in rdx
        push    rdx
        lea     rdi, [rel hash_syms]
        mov     esi, 1024
        call    hash_init
        lea     rdi, [rel hash_equs]
        mov     esi, 256
        call    hash_init
        mov     rdi, MAX_SOURCE_BYTES
        mov     esi, 16
        call    arena_alloc
        mov     [rel img_buf], rax
        pop     rcx                     ; path
        lea     rdi, [rel lex_st]
        mov     rsi, r12
        mov     rdx, r13
        call    lex_init
        mov     edi, 1
        call    run_pass
        mov     edi, 2
        call    run_pass
        mov     rax, [rel img_buf]
        mov     [r14], rax
        lea     rcx, [rel asm_st]
        mov     eax, [rcx + ASM_LC]
        sub     eax, GUEST_RESET
        mov     [r15], rax
        xor     eax, eax
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
