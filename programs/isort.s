# Insertion sort of 16 words. Exit 0 if sorted.

        .globl _start
_start:
        la      s0, arr
        li      s1, 16
        li      s2, 1                   # i
isort:
        bge     s2, s1, check
        slli    t0, s2, 2
        add     t0, t0, s0
        lw      s3, 0(t0)               # key
        addi    s4, s2, -1              # j
inner:
        bltz    s4, place
        slli    t0, s4, 2
        add     t0, t0, s0
        lw      t1, 0(t0)
        ble     t1, s3, place
        sw      t1, 4(t0)
        addi    s4, s4, -1
        j       inner
place:
        addi    t0, s4, 1
        slli    t0, t0, 2
        add     t0, t0, s0
        sw      s3, 0(t0)
        addi    s2, s2, 1
        j       isort
check:
        li      s2, 1
ck:
        bge     s2, s1, ok
        slli    t0, s2, 2
        add     t0, t0, s0
        lw      t1, 0(t0)
        lw      t2, -4(t0)
        blt     t1, t2, bad
        addi    s2, s2, 1
        j       ck
ok:
        li      a0, 0
        li      a7, 0
        ecall
bad:
        li      a0, 1
        li      a7, 0
        ecall

        .align  2
arr:
        .word 7,3,9,1,4,8,2,6,0,5,15,11,10,14,12,13
