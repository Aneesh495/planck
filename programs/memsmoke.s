# Load/store against the reset stack. Exit 0 if SW/LW round-trip 0.

        .globl _start
_start:
        sw      zero, 0(sp)
        lw      a0, 0(sp)
        li      a7, 0
        ecall
