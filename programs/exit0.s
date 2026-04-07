# Smallest well-formed guest: ecall exit 0.

        .globl _start
_start:
        li      a0, 0
        li      a7, 0
        ecall
