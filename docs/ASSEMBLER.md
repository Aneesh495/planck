# Assembler

Planck's assembler is a two-pass RV32IM assembler implemented in the same binary that will run the image. There is no `as` in the Docker image. Guest programs in `programs/*.s` are Planck syntax.

## Invocation

```
planck asm  [-o out.bin] in.s
planck run  in.s              # assemble to guest RAM, then execute
```

`run` with a `.s` does not write a file. `asm` does. The image is a raw binary, load address `0x80000000`, no ELF. ELF is a linker story; this is an assembler.

## Passes

**Pass 1.** Lex, parse, assign locations, record labels. `.align` and `.org` move the location counter. Instruction sizes are always 4. Data directives add their size. Unknown identifiers in immediates are assumed to be labels and recorded as relocs of type `abs32`, `pc_rel_b`, `pc_rel_j`, or `hi20`/`lo12` depending on operand class.

**Pass 2.** Resolve relocs, encode, write bytes into a host buffer, copy into guest RAM or a file.

A symbol referenced and never defined is a hard error with a line number. A duplicate label is a hard error. There is no weak, no STB_GLOBAL vs LOCAL other than “this string is the key.”

## Tokens

Whitespace and `,` are separators. `#` and `//` start a line comment. `/* */` is a block comment, non-nesting.

Identifiers: `[A-Za-z_.$][A-Za-z0-9_.$]*`

Integers: decimal, `0x` hex, `0b` binary, optional leading `-`. Character literals `'A'` with a short escape list `\n \t \\ \' \0`.

Strings: `"..."` with the same escapes. Used only in `.ascii` / `.asciiz`.

Registers: `x0`..`x31`, ABI names `zero ra sp gp tp t0-t6 s0/fp s1 s2-s11 a0-a7`.

## Directives

| Directive | Meaning |
|---|---|
| `.text` | location counter in code (default). Does not change load base. |
| `.data` | switch to data counter. For `run`, we still emit a single flat image; `.data` just continues at the current LC unless `.org` is used. |
| `.org n` | set LC to `n`. Must be ≥ current LC in a pass-1 image (no overlapping). |
| `.align p` | align LC to `2^p` with zero bytes (p ≤ 8). |
| `.byte n...` | emit 8-bit values |
| `.half n...` | 16-bit LE |
| `.word n...` | 32-bit LE |
| `.ascii "s"` | raw bytes, no NUL |
| `.asciiz "s"` | with NUL |
| `.space n` | n zero bytes |
| `.equ ident, n` | compile-time constant |
| `.globl ident` | accepted and ignored (single address space) |
| `.section name` | treated as `.text` or `.data` if the name contains those strings, else error |

## Instructions

All RV32IM mnemonics in [`ISA.md`](ISA.md), lowercase or uppercase. Operands in RISC-V conventional order: `rd, rs1, rs2` / `rd, rs1, imm` / `rs2, off(rs1)` for stores.

Loads/stores accept `imm(rs1)` with optional spaces: `lw a0, 16(sp)`.

Branches: `beq a0, a1, label`. The immediate is PC-relative and must fit a 13-bit signed offset with the implicit zero LSB (`±4 KiB`).

`jal rd, label`. J-type ±1 MiB. One-operand jumps are the pseudos `j` (`rd = x0`) and `call` (`rd = ra`).

## Pseudoinstructions

| Pseudo | Expansion |
|---|---|
| `nop` | `addi x0, x0, 0` |
| `li rd, imm` | `addi` if fits 12-bit; else `lui + addi` with the usual `+1` on LUI when `imm[11] = 1` |
| `mv rd, rs` | `addi rd, rs, 0` |
| `not rd, rs` | `xori rd, rs, -1` |
| `neg rd, rs` | `sub rd, x0, rs` |
| `seqz rd, rs` | `sltiu rd, rs, 1` |
| `snez rd, rs` | `sltu rd, x0, rs` |
| `sltz rd, rs` | `slt rd, rs, x0` |
| `sgtz rd, rs` | `slt rd, x0, rs` |
| `beqz rs, lab` | `beq rs, x0, lab` |
| `bnez rs, lab` | `bne rs, x0, lab` |
| `blez rs, lab` | `bge x0, rs, lab` |
| `bgez rs, lab` | `bge rs, x0, lab` |
| `bltz rs, lab` | `blt rs, x0, lab` |
| `bgtz rs, lab` | `blt x0, rs, lab` |
| `bgt a,b,l` | `blt b, a, l` |
| `ble a,b,l` | `bge b, a, l` |
| `bgtu a,b,l` | `bltu b, a, l` |
| `bleu a,b,l` | `bgeu b, a, l` |
| `j lab` | `jal x0, lab` |
| `jal rd, lab` | J-type; **rd is required** (`call lab` / `j lab` are the one-operand forms) |
| `jr rs` | `jalr x0, 0(rs)` |
| `ret` | `jalr x0, 0(ra)` |
| `call lab` | near `jal ra, lab` (must fit ±1 MiB) |
| `tail lab` | near `jal x0, lab` |
| `la rd, lab` | `auipc rd, hi` + `addi rd, rd, lo` |
| `fence` | `fence iorw, iorw` encoded as the I-type NOP-shaped fence |

`li` is the one everyone gets wrong. Planck uses the canonical:

```
lo = sext_12(imm[11:0])
hi = (imm - lo) >> 12     ; which is imm[31:12] + imm[11]
lui rd, hi
addi rd, rd, lo           ; omitted if lo == 0 and we already lui'd, or just addi if hi == 0
```

If the whole immediate fits in 12 bits, a single `addi rd, x0, imm`.

## Operand scratch (SysV)

The assembler is a forest of `call`s (`parse_reg` → `reg_lookup` → `ieq_n`, `parse_imm` → `hash_get`). Under the SysV AMD64 ABI, `rax rcx rdx rsi rdi r8–r11` are caller-saved.

Two concrete clobbers that ate a week:

- `reg_lookup` uses **`r8` as the register-table index**. After `add t4, t0, t1` the last lookup leaves `r8 = index(t1)`, not `rd = 29`.
- `hash_get` loads a slot pointer into **`r8`**, so a branch `bge t2, t3, done` that resolves `done` after stashing rs1/rs2 in `r8`/`r9` encodes garbage register fields and a nonsense displacement.

Decoded operands live in BSS `op_rd`, `op_rs1`, `op_rs2`, `op_imm` until `pack_*`. Callee-saved `r12`/`r13` are used only for `li`/`la`, which already survived because those functions push them.

See [`ENCODING.md`](ENCODING.md) for the bit layouts and the encode-path diagram.

## Relocations

| Kind | Applied to | Formula |
|---|---|---|
| `R_B` | B-type | `off = target - pc`, encode into bits 12,10:5,4:1,11 |
| `R_J` | J-type | `off = target - pc`, bits 20,10:1,11,19:12 |
| `R_HI20` | U-type | `((target - pc + 0x800) >> 12)` for AUIPC-relative, or `target >> 12` adjusted for `lui` |
| `R_LO12_I` | I-type | `sext_12` low |
| `R_LO12_S` | S-type | same bits, S packing |
| `R_ABS32` | `.word lab` | absolute guest address |

Out of range is a hard error with the two addresses printed in hex.

## Symbol table

Open-addressing hashmap, FNV-1a 64, 1024 slots to start, doubled on `> 3/4` load (arena allocation, never `realloc` in the libc sense). Values are `{addr, defined, line}`. The same hashmap type is used for `.equ`.

## Errors

The assembler prints:

```
programs/fib.s:42: error: branch target 0x80001004 out of range from 0x80000000
```

and exits 1. No recovery. One error per run is enough; the second is usually a cascade.

## Round trip

`planck asm in.s -o t.bin && planck disasm t.bin` is not guaranteed to produce the same *text* (pseudos become real insns, ABI names may be printed as `xN`), but re-assembling the disassembly must produce the same bytes. That is a test in `tests/test_asm.asm`.
