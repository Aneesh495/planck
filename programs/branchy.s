# Deterministic branch mix for the tournament predictor.

        .globl _start
_start:
        li      s0, 0
        li      s1, 0
        li      t0, 256
loop:
        andi    t1, s0, 1
        beqz    t1, odd
        addi    s1, s1, 1
        j       cont
odd:
        addi    s1, s1, 3
cont:
        andi    t1, s0, 3
        li      t2, 3
        bne     t1, t2, skip
        addi    s1, s1, 5
skip:
        addi    s0, s0, 1
        blt     s0, t0, loop
        # s1 = 128*1 + 128*3 + 64*5 = 128+384+320 = 832
        li      t0, 832
        bne     s1, t0, bad
        li      a0, 0
        li      a7, 0
        ecall
bad:
        li      a0, 1
        li      a7, 0
        ecall
