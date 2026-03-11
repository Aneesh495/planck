; src/asm/lexer.asm
; Tokeniser for Planck RV32 assembly. Newlines are tokens so the parser
; can recover at line boundaries. Comments: #, //, /* */.

        bits 64
        default rel

%include "macros.inc"
%include "asm.inc"

        extern is_space
        extern is_digit
        extern is_ident_start
        extern is_ident_cont
        extern parse_int
        extern hex_val

        section .text

; void lex_init(lex*, src, len, path)
PROC lex_init
        mov     [rdi + LEX_SRC], rsi
        mov     [rdi + LEX_LEN], rdx
        xor     eax, eax
        mov     [rdi + LEX_POS], eax
        mov     dword [rdi + LEX_LINE], 1
        mov     dword [rdi + LEX_COL], 1
        mov     [rdi + LEX_TOK], eax
        mov     [rdi + LEX_IVAL], eax
        mov     [rdi + LEX_SVAL], rax
        mov     [rdi + LEX_SLEN], eax
        mov     [rdi + LEX_PATH], rcx
        ret

; int lex_peek_char(lex*)  — 0 at EOF... actually returns char or -1
lex_peek:
        mov     eax, [rdi + LEX_POS]
        cmp     rax, [rdi + LEX_LEN]
        jae     .eof
        mov     rcx, [rdi + LEX_SRC]
        movzx   eax, byte [rcx + rax]
        ret
.eof:
        mov     eax, -1
        ret

lex_bump:
        ; consume one char, track line/col
        call    lex_peek
        cmp     eax, -1
        je      .done
        inc     dword [rdi + LEX_POS]
        cmp     eax, 10
        je      .nl
        inc     dword [rdi + LEX_COL]
        ret
.nl:
        inc     dword [rdi + LEX_LINE]
        mov     dword [rdi + LEX_COL], 1
.done:
        ret

skip_spaces:
        push    rbx
        mov     rbx, rdi
.loop:
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, -1
        je      .out
        cmp     eax, 10
        je      .out                    ; newline is a token
        mov     edi, eax
        call    is_space
        test    eax, eax
        jz      .out
        mov     rdi, rbx
        call    lex_bump
        jmp     .loop
.out:
        pop     rbx
        ret

skip_line_comment:
.loop:
        call    lex_peek
        cmp     eax, -1
        je      .out
        cmp     eax, 10
        je      .out
        call    lex_bump
        jmp     .loop
.out:
        ret

skip_block_comment:
        ; already consumed '/' of '/*'? caller consumed both
.loop:
        call    lex_peek
        cmp     eax, -1
        je      .out
        cmp     eax, '*'
        jne     .n
        call    lex_bump
        call    lex_peek
        cmp     eax, '/'
        jne     .loop
        call    lex_bump
        jmp     .out
.n:
        call    lex_bump
        jmp     .loop
.out:
        ret

; int lex_next(lex*)  — sets LEX_TOK, returns it
PROC lex_next
        push    rbx
        push    r12
        mov     rbx, rdi
.retry:
        mov     rdi, rbx
        call    skip_spaces
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, -1
        je      .eof
        cmp     eax, 10
        je      .nl
        cmp     eax, '#'
        je      .hash
        cmp     eax, '/'
        je      .slash
        cmp     eax, ','
        je      .comma
        cmp     eax, '('
        je      .lpar
        cmp     eax, ')'
        je      .rpar
        cmp     eax, ':'
        je      .colon
        cmp     eax, '+'
        je      .plus
        cmp     eax, '-'
        je      .minus_or_num
        cmp     eax, '"'
        je      .string
        cmp     eax, 39                 ; '
        je      .char
        ; ident or number or dot-ident
        mov     r12d, eax
        mov     edi, eax
        call    is_ident_start
        test    eax, eax
        jnz     .ident
        mov     edi, r12d
        call    is_digit
        test    eax, eax
        jnz     .number
        jmp     .error

.eof:
        mov     dword [rbx + LEX_TOK], TOK_EOF
        mov     eax, TOK_EOF
        jmp     .out
.nl:
        mov     rdi, rbx
        call    lex_bump
        mov     dword [rbx + LEX_TOK], TOK_NL
        mov     eax, TOK_NL
        jmp     .out
.hash:
        mov     rdi, rbx
        call    skip_line_comment
        jmp     .retry
.slash:
        mov     rdi, rbx
        call    lex_bump
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, '/'
        je      .sl2
        cmp     eax, '*'
        je      .sl3
        ; lone '/' is error
        jmp     .error
.sl2:
        mov     rdi, rbx
        call    skip_line_comment
        jmp     .retry
.sl3:
        mov     rdi, rbx
        call    lex_bump
        mov     rdi, rbx
        call    skip_block_comment
        jmp     .retry
.comma:
        mov     rdi, rbx
        call    lex_bump
        mov     dword [rbx + LEX_TOK], TOK_COMMA
        mov     eax, TOK_COMMA
        jmp     .out
.lpar:
        mov     rdi, rbx
        call    lex_bump
        mov     dword [rbx + LEX_TOK], TOK_LPAREN
        mov     eax, TOK_LPAREN
        jmp     .out
.rpar:
        mov     rdi, rbx
        call    lex_bump
        mov     dword [rbx + LEX_TOK], TOK_RPAREN
        mov     eax, TOK_RPAREN
        jmp     .out
.colon:
        mov     rdi, rbx
        call    lex_bump
        mov     dword [rbx + LEX_TOK], TOK_COLON
        mov     eax, TOK_COLON
        jmp     .out
.plus:
        mov     rdi, rbx
        call    lex_bump
        mov     dword [rbx + LEX_TOK], TOK_PLUS
        mov     eax, TOK_PLUS
        jmp     .out
.minus_or_num:
        ; look ahead: if digit, parse negative int
        mov     rdi, rbx
        call    lex_bump                ; consume '-'
        mov     rdi, rbx
        call    lex_peek
        mov     edi, eax
        cmp     edi, -1
        je      .just_minus
        call    is_digit
        test    eax, eax
        jz      .just_minus
        ; parse int including the minus: back up one
        dec     dword [rbx + LEX_POS]
        dec     dword [rbx + LEX_COL]
        jmp     .number
.just_minus:
        mov     dword [rbx + LEX_TOK], TOK_MINUS
        mov     eax, TOK_MINUS
        jmp     .out

.ident:
        mov     rax, [rbx + LEX_SRC]
        mov     ecx, [rbx + LEX_POS]
        add     rax, rcx
        mov     [rbx + LEX_SVAL], rax
        xor     r12d, r12d
.idloop:
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, -1
        je      .iddone
        mov     edi, eax
        call    is_ident_cont
        test    eax, eax
        jz      .iddone
        mov     rdi, rbx
        call    lex_bump
        inc     r12d
        jmp     .idloop
.iddone:
        mov     [rbx + LEX_SLEN], r12d
        mov     dword [rbx + LEX_TOK], TOK_IDENT
        mov     eax, TOK_IDENT
        jmp     .out

.number:
        mov     rax, [rbx + LEX_SRC]
        mov     ecx, [rbx + LEX_POS]
        add     rax, rcx
        mov     r12, rax                ; start
        xor     r8d, r8d                ; len
.nloop:
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, -1
        je      .ndone
        ; allow x b X B a-f for prefixes
        mov     edi, eax
        call    is_ident_cont
        test    eax, eax
        jz      .ndone
        mov     rdi, rbx
        call    lex_bump
        inc     r8d
        jmp     .nloop
.ndone:
        ; parse_int(s, len, &ival)
        mov     rdi, r12
        mov     esi, r8d
        lea     rdx, [rbx + LEX_IVAL]
        call    parse_int
        test    eax, eax
        jnz     .error
        mov     dword [rbx + LEX_TOK], TOK_INT
        mov     eax, TOK_INT
        jmp     .out

.string:
        mov     rdi, rbx
        call    lex_bump                ; "
        mov     rax, [rbx + LEX_SRC]
        mov     ecx, [rbx + LEX_POS]
        add     rax, rcx
        mov     [rbx + LEX_SVAL], rax
        xor     r12d, r12d
.sloop:
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, -1
        je      .error
        cmp     eax, '"'
        je      .sdone
        cmp     eax, 10
        je      .error
        cmp     eax, '\'
        jne     .snorm
        mov     rdi, rbx
        call    lex_bump
        inc     r12d
.snorm:
        mov     rdi, rbx
        call    lex_bump
        inc     r12d
        jmp     .sloop
.sdone:
        mov     [rbx + LEX_SLEN], r12d
        mov     rdi, rbx
        call    lex_bump                ; closing "
        mov     dword [rbx + LEX_TOK], TOK_STR
        mov     eax, TOK_STR
        jmp     .out

.char:
        mov     rdi, rbx
        call    lex_bump
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, '\'
        jne     .ch1
        mov     rdi, rbx
        call    lex_bump
        mov     rdi, rbx
        call    lex_peek
        call    escape_char
        mov     [rbx + LEX_IVAL], eax
        mov     rdi, rbx
        call    lex_bump
        jmp     .chclose
.ch1:
        mov     [rbx + LEX_IVAL], eax
        mov     rdi, rbx
        call    lex_bump
.chclose:
        mov     rdi, rbx
        call    lex_peek
        cmp     eax, 39
        jne     .error
        mov     rdi, rbx
        call    lex_bump
        mov     dword [rbx + LEX_TOK], TOK_CHAR
        mov     eax, TOK_CHAR
        jmp     .out

.error:
        mov     dword [rbx + LEX_TOK], TOK_ERROR
        mov     eax, TOK_ERROR
.out:
        pop     r12
        pop     rbx
        ret

; int escape_char(int c)  — edi = char after backslash
escape_char:
        cmp     edi, 'n'
        je      .n
        cmp     edi, 't'
        je      .t
        cmp     edi, 'r'
        je      .r
        cmp     edi, '0'
        je      .z
        cmp     edi, '\'
        je      .bs
        cmp     edi, 39
        je      .q
        cmp     edi, '"'
        je      .dq
        mov     eax, edi
        ret
.n:     mov     eax, 10
        ret
.t:     mov     eax, 9
        ret
.r:     mov     eax, 13
        ret
.z:     xor     eax, eax
        ret
.bs:    mov     eax, '\'
        ret
.q:     mov     eax, 39
        ret
.dq:    mov     eax, '"'
        ret
