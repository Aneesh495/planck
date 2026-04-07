# fact(8) = 40320

        .globl _start
_start:
        li      a0, 8
        li      t0, 1
        li      t1, 1
floop:
        bgt     t1, a0, done
        mul     t0, t0, t1
        addi    t1, t1, 1
        j       floop
done:
        li      t1, 40320
        bne     t0, t1, bad
        li      a0, 0
        li      a7, 0
        ecall
bad:
        li      a0, 1
        li      a7, 0
        ecall
