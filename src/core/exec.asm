; src/core/exec.asm
; Functional execute dispatch. Jump table indexed by DEC_ID.

        bits 64
        default rel

%include "macros.inc"
%include "rv32.inc"
%include "cpu.inc"

        extern exec_illegal
        extern exec_lui
        extern exec_auipc
        extern exec_jal
        extern exec_jalr
        extern exec_beq
        extern exec_bne
        extern exec_blt
        extern exec_bge
        extern exec_bltu
        extern exec_bgeu
        extern exec_lb
        extern exec_lh
        extern exec_lw
        extern exec_lbu
        extern exec_lhu
        extern exec_sb
        extern exec_sh
        extern exec_sw
        extern exec_addi
        extern exec_slti
        extern exec_sltiu
        extern exec_xori
        extern exec_ori
        extern exec_andi
        extern exec_slli
        extern exec_srli
        extern exec_srai
        extern exec_add
        extern exec_sub
        extern exec_sll
        extern exec_slt
        extern exec_sltu
        extern exec_xor
        extern exec_srl
        extern exec_sra
        extern exec_or
        extern exec_and
        extern exec_fence
        extern exec_ecall
        extern exec_ebreak
        extern exec_csrrw
        extern exec_csrrs
        extern exec_csrrc
        extern exec_csrrwi
        extern exec_csrrsi
        extern exec_csrrci
        extern exec_mul
        extern exec_mulh
        extern exec_mulhsu
        extern exec_mulhu
        extern exec_div
        extern exec_divu
        extern exec_rem
        extern exec_remu
        extern exec_mret

        section .rodata
        align 8
exec_table:
        dq exec_illegal
        dq exec_lui
        dq exec_auipc
        dq exec_jal
        dq exec_jalr
        dq exec_beq
        dq exec_bne
        dq exec_blt
        dq exec_bge
        dq exec_bltu
        dq exec_bgeu
        dq exec_lb
        dq exec_lh
        dq exec_lw
        dq exec_lbu
        dq exec_lhu
        dq exec_sb
        dq exec_sh
        dq exec_sw
        dq exec_addi
        dq exec_slti
        dq exec_sltiu
        dq exec_xori
        dq exec_ori
        dq exec_andi
        dq exec_slli
        dq exec_srli
        dq exec_srai
        dq exec_add
        dq exec_sub
        dq exec_sll
        dq exec_slt
        dq exec_sltu
        dq exec_xor
        dq exec_srl
        dq exec_sra
        dq exec_or
        dq exec_and
        dq exec_fence
        dq exec_ecall
        dq exec_ebreak
        dq exec_csrrw
        dq exec_csrrs
        dq exec_csrrc
        dq exec_csrrwi
        dq exec_csrrsi
        dq exec_csrrci
        dq exec_mul
        dq exec_mulh
        dq exec_mulhsu
        dq exec_mulhu
        dq exec_div
        dq exec_divu
        dq exec_rem
        dq exec_remu
        dq exec_mret

        section .text

; void pc_advance(cpu*)
PROC pc_advance
        add     qword [rdi + CPU_PC], 4
        ret

; void exec_decoded(cpu*, dec_t*)
PROC exec_decoded
        mov     eax, [rsi + DEC_ID]
        cmp     eax, ID_COUNT
        jae     .ill
        lea     rcx, [rel exec_table]
        mov     rax, [rcx + rax*8]
        jmp     rax
.ill:
        jmp     exec_illegal
