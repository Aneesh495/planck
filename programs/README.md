# `programs/`

RV32IM guests assembled by Planck itself (`planck run file.s`). Each image exits 0 if its own checksum/assertion passed.

| Program | Check |
|---|---|
| `exit0.s` | empty success |
| `fib.s` | iterative fib(8) = 21 |
| `fib_rec.s` | recursive fib(8) = 21 |
| `fact.s` | 8! = 40320 |
| `memcpy.s` | 32-byte copy matches |
| `isort.s` | 16 words sorted |
| `matmul.s` | 8×8 integer MM checksum 288 |
| `branchy.s` | mixed branches, `s1 = 832` |
| `crc32.s` | IEEE CRC-32 of `hello, planck!` |

Full commentary, the `ecall` convention, and how to add a program: [`docs/PROGRAMS.md`](../docs/PROGRAMS.md).
