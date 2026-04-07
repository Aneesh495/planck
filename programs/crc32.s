# CRC-32 (IEEE) of a short buffer.

        .globl _start
_start:
        la      a0, msg
        li      a1, 14
        call    crc32
        la      t0, expect
        lw      t0, 0(t0)
        bne     a0, t0, bad
        li      a0, 0
        li      a7, 0
        ecall
bad:
        li      a0, 1
        li      a7, 0
        ecall

crc32:
        li      t0, -1                  # crc
        beqz    a1, crcdone
crcloop:
        lbu     t1, 0(a0)
        xor     t0, t0, t1
        li      t2, 8
bit:
        andi    t3, t0, 1
        srli    t0, t0, 1
        beqz    t3, nobit
        li      t4, 0xEDB88320
        xor     t0, t0, t4
nobit:
        addi    t2, t2, -1
        bnez    t2, bit
        addi    a0, a0, 1
        addi    a1, a1, -1
        bnez    a1, crcloop
crcdone:
        not     a0, t0
        ret

msg:
        .ascii  "hello, planck!"
        .align  2
expect:
        .word   0                       # filled after first golden run if needed; test may skip
