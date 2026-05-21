# Iterative fib(8) == 21. Exit 0 on success. No call/ret.

        .globl _start
_start:
        li      t0, 0                   # a
        li      t1, 1                   # b
        li      t2, 0                   # i
        li      t3, 8                   # n
loop:
        bge     t2, t3, done
        add     t4, t0, t1
        mv      t0, t1
        mv      t1, t4
        addi    t2, t2, 1
        j       loop
done:
        li      t3, 21
        bne     t0, t3, fail
        li      a0, 0
        li      a7, 0
        ecall
fail:
        li      a0, 1
        li      a7, 0
        ecall
