# memcpy then compare. Exercises unaligned-ish word copies.

        .globl _start
_start:
        la      a0, dst
        la      a1, src
        li      a2, 32
        call    memcpy
        la      a0, dst
        la      a1, src
        li      a2, 32
        call    memcmp
        bne     a0, x0, bad
        li      a0, 0
        li      a7, 0
        ecall
bad:
        li      a0, 1
        li      a7, 0
        ecall

memcpy:
        beqz    a2, mdone
mloop:
        lb      t0, 0(a1)
        sb      t0, 0(a0)
        addi    a0, a0, 1
        addi    a1, a1, 1
        addi    a2, a2, -1
        bnez    a2, mloop
mdone:
        ret

memcmp:
        beqz    a2, eq
cloop:
        lbu     t0, 0(a0)
        lbu     t1, 0(a1)
        bne     t0, t1, ne
        addi    a0, a0, 1
        addi    a1, a1, 1
        addi    a2, a2, -1
        bnez    a2, cloop
eq:
        li      a0, 0
        ret
ne:
        li      a0, 1
        ret

src:
        .ascii  "0123456789abcdef0123456789abcdef"
dst:
        .space  32
