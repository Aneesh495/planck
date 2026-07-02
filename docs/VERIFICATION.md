# Verification

Planck has two cores and one spec. The spec is the functional interpreter plus [`ISA.md`](ISA.md). Everything else is guilty until it matches.

## Layers

```mermaid
flowchart TB
  U[unit tests in tests/*.asm]
  G[guest programs in programs/*.s]
  X[cross-check functional vs OoO]
  U --> H[planck test]
  G --> R[planck run]
  G --> X
  X --> H
```

`planck test` is an assembly program linked into the same binary, not a Python runner. It calls exported `test_*` functions, each of which prints `ok  <name>` or `FAIL <name> <detail>` and bumps a fail counter. Exit code is the fail count.

## Unit tests (host-side)

These poke structures without a guest:

| File | Claims |
|---|---|
| `tests/test_hash.asm` | FNV hashmap put/get/grow/miss |
| `tests/test_decode.asm` | hand-encoded insns → fields |
| `tests/test_alu.asm` | every ALU op including SRA sign, SLTU edge |
| `tests/test_m.asm` | MULHSU, DIV by zero, INT_MIN/-1 |
| `tests/test_mem.asm` | unaligned LW/SW, sign extend LB |
| `tests/test_branch.asm` | taken/not, JALR bit0 clear |
| `tests/test_asm.asm` | assemble string, compare bytes to `pack_*` (ABI names, R/B/`mv`/`slli`) |
| `tests/test_cache.asm` | LRU sequence, write-back dirty, MSHR merge |
| `tests/test_programs.asm` | assemble `li`/`ecall`, `interp_run`, halt 0 |

Each ALU test is of the form: reset CPU, write `x1, x2`, plant one insn at the reset vector, `interp_step`, compare `x3` and `pc`.

## Guest programs (end-to-end)

Catalog and how to add one: [`PROGRAMS.md`](PROGRAMS.md). CI (`planck run`) is the pass/fail gate.

| Program | Why it exists |
|---|---|
| `programs/exit0.s` | smallest image |
| `programs/fib.s` | iterative loop, ABI-named R/B types |
| `programs/fib_rec.s` | `call`/`ret`, stack, RAS |
| `programs/fact.s` | linear `mul` chain |
| `programs/memcpy.s` | byte copy, `la`, `beqz` |
| `programs/isort.s` | insertion sort, negative load offset |
| `programs/matmul.s` | nested loops, `slli`, I$ + D$ pressure |
| `programs/branchy.s` | deterministic mix for the tournament predictor |
| `programs/crc32.s` | `lbu`/`srli`/`xor`, wide `li` of the IEEE poly |

Each program `ecall`s with `a7 = 0`. `a0 = 0` means its own checksum passed. `planck test` covers assembler/ALU/cache units; the programs above are run from GitHub Actions as separate steps.

## Cross-check protocol

```
assemble(src) -> image A
cpu_reset; load A; functional until halt; snapshot regs, fold RAM
cpu_reset; load A; ooo until halt or max_cycle; snapshot
compare
```

Mismatch prints the first register that differed and the last 16 committed PCs from the ROB trace ring. That ring is 16 deep and exists only because this compare failed while the core was being written.

## What we do not test

- Multi-hart races (no second hart).
- Page table walks (identity only).
- IEEE-754.
- C extension.
- Linux binaries.

## Reproducing a failure

```
./bin/planck run --trace --dump-regs programs/foo.s
./bin/planck run --mode ooo --stats --dump-regs programs/foo.s
```

`--trace` in functional mode prints `pc inst disasm` per retire. In OoO it prints at **commit**, so the stream should match functional if the core is correct. If `--trace` streams diverge, the bug is in retire order, not in fetch.

## CI

`.github/workflows/ci.yml` builds the Docker image on `ubuntu-latest` (`linux/amd64`) and runs `planck test` and a subset of `planck run --mode ooo`. Apple Silicon contributors use the same Dockerfile locally with `--platform linux/amd64`.
