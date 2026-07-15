# la + lw of a word in the image. Exit 0 if the word is 0.

        .globl _start
_start:
        la      a0, val
        lw      a1, 0(a0)
        bne     a1, zero, bad
        li      a0, 0
        li      a7, 0
        ecall
bad:
        li      a0, 1
        li      a7, 0
        ecall
        .align  2
val:
        .word   0
