# call/ret smoke test. Exit 0 if ra round-trips.

        .globl _start
_start:
        call    leaf
        bne     a0, x0, fail
        li      a0, 0
        li      a7, 0
        ecall
fail:
        li      a0, 1
        li      a7, 0
        ecall
leaf:
        li      a0, 0
        ret
