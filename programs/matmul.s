# Integer 8x8 matrix multiply. C = A * B, checksum in a0, exit 0 if match.

        .globl _start
_start:
        li      t0, 8                   # n
        la      s0, A
        la      s1, B
        la      s2, C
        li      s3, 0                   # i
i_loop:
        li      s4, 0                   # j
j_loop:
        li      t1, 0                   # acc
        li      s5, 0                   # k
k_loop:
        # A[i][k] = A + (i*8+k)*4
        slli    t2, s3, 3
        add     t2, t2, s5
        slli    t2, t2, 2
        add     t2, t2, s0
        lw      t3, 0(t2)
        slli    t2, s5, 3
        add     t2, t2, s4
        slli    t2, t2, 2
        add     t2, t2, s1
        lw      t4, 0(t2)
        mul     t3, t3, t4
        add     t1, t1, t3
        addi    s5, s5, 1
        blt     s5, t0, k_loop
        slli    t2, s3, 3
        add     t2, t2, s4
        slli    t2, t2, 2
        add     t2, t2, s2
        sw      t1, 0(t2)
        addi    s4, s4, 1
        blt     s4, t0, j_loop
        addi    s3, s3, 1
        blt     s3, t0, i_loop
        # checksum
        li      t1, 0
        li      s3, 0
        li      t5, 64
sum:
        slli    t2, s3, 2
        add     t2, t2, s2
        lw      t3, 0(t2)
        add     t1, t1, t3
        addi    s3, s3, 1
        blt     s3, t5, sum
        la      t0, expect
        lw      t0, 0(t0)
        bne     t1, t0, bad
        li      a0, 0
        li      a7, 0
        ecall
bad:
        li      a0, 1
        li      a7, 0
        ecall

        .align  2
A:
        .word 1,0,0,0,0,0,0,0
        .word 0,1,0,0,0,0,0,0
        .word 0,0,1,0,0,0,0,0
        .word 0,0,0,1,0,0,0,0
        .word 0,0,0,0,1,0,0,0
        .word 0,0,0,0,0,1,0,0
        .word 0,0,0,0,0,0,1,0
        .word 0,0,0,0,0,0,0,1
B:
        .word 1,2,3,4,5,6,7,8
        .word 1,2,3,4,5,6,7,8
        .word 1,2,3,4,5,6,7,8
        .word 1,2,3,4,5,6,7,8
        .word 1,2,3,4,5,6,7,8
        .word 1,2,3,4,5,6,7,8
        .word 1,2,3,4,5,6,7,8
        .word 1,2,3,4,5,6,7,8
C:
        .space 256
expect:
        .word 288                       # identity * B row-sum 36 * 8 = 288
