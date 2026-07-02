# Guest programs

Every file in `programs/` is RV32IM source assembled **by Planck**, not by `riscv64-unknown-elf-as`. `planck run foo.s` is assemble-into-guest-RAM then execute. Exit code `0` means the program's own assertion passed (`ecall` with `a7 = 0`, `a0 = 0`). Exit code `1` is a failed check. Any other halt is a trap (`reason=3` illegal, access fault, …).

Reset: `pc = 0x80000000`, `sp = 0x80000000 + mem_size - 16`, `x0` wired zero. There is no CRT, no `gp`, no argv.

## Suite

| File | What it proves | Notes |
|---|---|---|
| [`exit0.s`](../programs/exit0.s) | smallest legal image | `li` + `ecall` |
| [`fib.s`](../programs/fib.s) | loop, `add`, `bge`, `mv`, `j` | iterative `fib(8) == 21` |
| [`fib_rec.s`](../programs/fib_rec.s) | `call`/`ret`, stack, RAS | recursive `fib(8)`, `s0`/`s1` saved |
| [`fact.s`](../programs/fact.s) | `mul`, `bgt` | `8! = 40320` |
| [`memcpy.s`](../programs/memcpy.s) | `lb`/`sb`, `beqz`/`bnez`, `la` | 32-byte copy then `memcmp` |
| [`isort.s`](../programs/isort.s) | loads/stores, negative offset, `ble`/`bltz` | insertion sort of 16 words |
| [`matmul.s`](../programs/matmul.s) | nested loops, `slli`, 8×8 integer GEMM | identity × B, checksum 288 |
| [`branchy.s`](../programs/branchy.s) | mixed taken/not-taken | 256-iter mix, expected `s1 = 832` |
| [`crc32.s`](../programs/crc32.s) | `lbu`, `andi`, `srli`, `not`, wide `li` | IEEE CRC-32 of `hello, planck!` = `0xdb2efe73` |

CI runs each of these under the functional interpreter. `fib.s` is also run with `--mode ooo --stats`.

## Writing a new one

```
        .globl _start
_start:
        ...
        li      a0, 0          # status
        li      a7, 0          # SYS_EXIT
        ecall
```

Conventions that match the assembler:

- Lowercase mnemonics, ABI names (`t0`, `a0`, `sp`, …) or `xN`.
- `#` line comments.
- Labels are identifiers followed by `:`. They may sit on their own line.
- `.word` / `.ascii` / `.space` / `.align p` (align to `2^p`) / `.equ` / `.globl` (ignored).
- `call lab` is a near `jal ra, lab`. Keep callees inside ±1 MiB of the call site.
- `la rd, lab` is `auipc`+`addi` PC-relative. Put data in the same image after code; do not assume a separate `.data` linker segment.

Self-checks belong in the guest: compute a number, `bne` to `fail` which exits 1. Do not depend on host `--dump-regs` for pass/fail.

## Why these and not SPEC

The point is coverage of **this** core and **this** assembler: every RV32I format, M-extension multiply, stack discipline, and a predictor-hostile branch mix. A SPEC-sized integer kernel would hide bugs in noise and in the host model cost. `matmul.s` is already enough nested-loop I$/D$ traffic to make `--stats` interesting.
