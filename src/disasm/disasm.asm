; src/disasm/disasm.asm
; Print a decoded RV32 instruction. Names come from the assembler table.

        bits 64
        default rel

%include "macros.inc"
%include "rv32.inc"
%include "syscall.inc"

        extern decode_inst
        extern mnem_tab
        extern mnem_count
        extern io_cstr
        extern io_hex32
        extern io_sp
        extern io_chr
        extern io_dec
        extern io_nl
        extern io_udec

        section .rodata
unk:            db "unknown",0
sep:            db ", ",0
lp:             db "(",0
rp:             db ")",0
xn:             db "x",0

        section .bss
        align 16
ddec:           resb DEC_SIZEOF

        section .text

; const char *id_name(uint32 id, uint32 *len)
id_name:
        push    rbx
        push    r12
        mov     r12d, edi
        lea     rbx, [rel mnem_tab]
        mov     eax, [rel mnem_count]
        xor     ecx, ecx
.loop:
        cmp     ecx, eax
        jge     .miss
        cmp     dword [rbx + 12], r12d  ; MNEM_ID
        jne     .n
        cmp     dword [rbx + 16], 9     ; skip FORM_PSEUDO = 9
        je      .n
        mov     rax, [rbx]
        mov     edx, [rbx + 8]
        mov     [rsi], edx
        pop     r12
        pop     rbx
        ret
.n:
        add     rbx, 32
        inc     ecx
        jmp     .loop
.miss:
        lea     rax, [rel unk]
        mov     dword [rsi], 7
        pop     r12
        pop     rbx
        ret

; void disasm_print_reg(int fd, uint32 r)
print_reg:
        push    rdi
        push    rsi
        mov     esi, 'x'
        call    io_chr
        pop     rsi
        pop     rdi
        mov     eax, esi
        mov     esi, eax
        xor     edx, edx
        mov     ecx, 10
        jmp     io_udec

; void disasm_inst(int fd, uint32 inst, uint32 pc)
PROC disasm_inst
        push    rbx
        push    r12
        push    r13
        mov     ebx, edi                ; fd
        mov     r12d, esi               ; inst
        mov     r13d, edx               ; pc
        mov     edi, r12d
        mov     esi, r13d
        lea     rdx, [rel ddec]
        call    decode_inst
        ; pc
        mov     edi, ebx
        mov     esi, r13d
        call    io_hex32
        mov     edi, ebx
        call    io_sp
        mov     edi, ebx
        mov     esi, r12d
        call    io_hex32
        mov     edi, ebx
        call    io_sp
        ; name
        sub     rsp, 8
        mov     edi, [rel ddec + DEC_ID]
        mov     rsi, rsp
        call    id_name
        mov     rsi, rax
        ; write n bytes not cstr — names are not NUL-terminated!
        mov     edx, [rsp]
        mov     edi, ebx
        extern sys_write
        call    sys_write
        add     rsp, 8
        mov     edi, ebx
        call    io_sp
        mov     eax, [rel ddec + DEC_ID]
        cmp     eax, ID_ILLEGAL
        je      .nl
        cmp     eax, ID_LUI
        je      .u
        cmp     eax, ID_AUIPC
        je      .u
        cmp     eax, ID_JAL
        je      .j
        cmp     eax, ID_JALR
        je      .i
        cmp     eax, ID_BEQ
        jb      .nl
        cmp     eax, ID_BGEU
        jbe     .b
        cmp     eax, ID_LB
        jb      .nl
        cmp     eax, ID_LHU
        jbe     .load
        cmp     eax, ID_SB
        jb      .nl
        cmp     eax, ID_SW
        jbe     .s
        cmp     eax, ID_ADDI
        jb      .nl
        cmp     eax, ID_AND
        jbe     .alu
        cmp     eax, ID_ECALL
        je      .nl
        cmp     eax, ID_EBREAK
        je      .nl
        cmp     eax, ID_FENCE
        je      .nl
        cmp     eax, ID_MRET
        je      .nl
        cmp     eax, ID_MUL
        jb      .csr
        jmp     .r

.u:
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RD]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_IMM]
        shr     esi, 12
        call    io_hex32
        jmp     .nl
.j:
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RD]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     eax, r13d
        add     eax, [rel ddec + DEC_IMM]
        mov     edi, ebx
        mov     esi, eax
        call    io_hex32
        jmp     .nl
.b:
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS1]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS2]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     eax, r13d
        add     eax, [rel ddec + DEC_IMM]
        mov     edi, ebx
        mov     esi, eax
        call    io_hex32
        jmp     .nl
.load:
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RD]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_IMM]
        xor     edx, edx
        mov     ecx, 10
        extern io_i64
        movsxd  rsi, esi
        call    io_i64
        mov     edi, ebx
        lea     rsi, [rel lp]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS1]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel rp]
        call    io_cstr
        jmp     .nl
.s:
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS2]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_IMM]
        movsxd  rsi, esi
        xor     edx, edx
        mov     ecx, 10
        call    io_i64
        mov     edi, ebx
        lea     rsi, [rel lp]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS1]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel rp]
        call    io_cstr
        jmp     .nl
.i:
.alu:
        ; rd, rs1, rs2 or imm
        mov     eax, [rel ddec + DEC_ID]
        cmp     eax, ID_ADD
        jae     .r
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RD]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS1]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_IMM]
        movsxd  rsi, esi
        xor     edx, edx
        mov     ecx, 10
        call    io_i64
        jmp     .nl
.r:
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RD]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS1]
        call    print_reg
        mov     edi, ebx
        lea     rsi, [rel sep]
        call    io_cstr
        mov     edi, ebx
        mov     esi, [rel ddec + DEC_RS2]
        call    print_reg
        jmp     .nl
.csr:
        jmp     .nl
.nl:
        mov     edi, ebx
        call    io_nl
        pop     r13
        pop     r12
        pop     rbx
        ret

; void disasm_image(int fd, void *img, uint64 len, uint32 base)
PROC disasm_image
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     ebx, edi
        mov     r12, rsi
        mov     r13, rdx
        mov     r14d, ecx
        xor     r8d, r8d
.loop:
        cmp     r8, r13
        jae     .out
        mov     eax, [r12 + r8]
        push    r8
        mov     edi, ebx
        mov     esi, eax
        mov     edx, r14d
        add     edx, r8d
        call    disasm_inst
        pop     r8
        add     r8, 4
        jmp     .loop
.out:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret
