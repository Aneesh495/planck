# fib(8) == 21. Exit 0 on success.

        .globl _start
_start:
        li      a0, 8
        call    fib
        li      t0, 21
        bne     a0, t0, fail
        li      a0, 0
        li      a7, 0
        ecall
fail:
        li      a0, 1
        li      a7, 0
        ecall

fib:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        mv      s0, a0
        li      t0, 2
        blt     s0, t0, base
        addi    a0, s0, -1
        call    fib
        mv      s1, a0
        addi    a0, s0, -2
        call    fib
        add     a0, a0, s1
        j       done
base:
        mv      a0, s0
done:
        lw      ra, 12(sp)
        lw      s0, 8(sp)
        lw      s1, 4(sp)
        addi    sp, sp, 16
        ret
