# ISA

Planck implements **RV32IM** in machine mode, plus the CSRs required to make `mcycle` / `minstret` / traps honest.

Unprivileged encodings follow *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA* (we track the 20191213 frozen RV32I plus the M extension as ratified). Privileged CSRs follow Volume II enough to take traps and return from them. We do not implement page tables, S-mode, or the A extension.

## Privilege and reset

| State | Reset value |
|---|---|
| `pc` | `0x80000000` |
| `x0` | `0` (hardwired) |
| `x1..x31` | `0` |
| `sp` (`x2`) | `mem_base_guest + mem_size - 16` after `cpu_reset` |
| privilege | M |
| `mstatus` | `MPP = M`, other bits 0 |
| `mtvec` | `0` (untargeted traps halt) |
| `mcycle`, `minstret` | `0` |

## Instruction formats

```
31        25 24    20 19    15 14  12 11     7 6      0
┌───────────┬────────┬────────┬──────┬────────┬────────┐
│  funct7   │  rs2   │  rs1   │funct3│   rd   │ opcode │ R
├───────────┴────────┤        │      │        │        │
│       imm[11:0]    │  rs1   │funct3│   rd   │ opcode │ I
├───────────┬────────┤        │      │        │        │
│ imm[11:5] │  rs2   │  rs1   │funct3│imm[4:0]│ opcode │ S
├───────────┬────────┤        │      │        │        │
│imm[12|10:5]│  rs2  │  rs1   │funct3│imm[4:1|11]│opcode│ B
├───────────┴────────┴────────┴──────┤        │        │
│            imm[31:12]              │   rd   │ opcode │ U
├────────────────────────────────────┴────────┤        │
│   imm[20|10:1|11|19:12]                     │   rd   │ opcode │ J
└─────────────────────────────────────────────┴────────┴────────┘
```

Immediates are sign-extended to 32 bits except `u`-type, which fills `[31:12]` and zeros the rest.

## Opcodes implemented

### RV32I

| Mnemonic | Form | Opcode | funct3 | funct7 | Semantics |
|---|---|---|---|---|---|
| `LUI` | U | `0110111` | | | `rd = imm` |
| `AUIPC` | U | `0010111` | | | `rd = pc + imm` |
| `JAL` | J | `1101111` | | | `rd = pc+4; pc += imm` |
| `JALR` | I | `1100111` | 000 | | `rd = pc+4; pc = (rs1+imm) & ~1` |
| `BEQ` | B | `1100011` | 000 | | `pc += imm` if `rs1 == rs2` |
| `BNE` | B | | 001 | | ≠ |
| `BLT` | B | | 100 | | signed < |
| `BGE` | B | | 101 | | signed ≥ |
| `BLTU` | B | | 110 | | unsigned < |
| `BGEU` | B | | 111 | | unsigned ≥ |
| `LB` `LH` `LW` `LBU` `LHU` | I | `0000011` | 000/001/010/100/101 | | sign/zero extend |
| `SB` `SH` `SW` | S | `0100011` | 000/001/010 | | |
| `ADDI` | I | `0010011` | 000 | | |
| `SLTI` | I | | 010 | | signed < imm |
| `SLTIU` | I | | 011 | | unsigned < imm |
| `XORI` `ORI` `ANDI` | I | | 100/110/111 | | |
| `SLLI` | I | | 001 | `0000000` | shift amt `imm[4:0]` |
| `SRLI` | I | | 101 | `0000000` | |
| `SRAI` | I | | 101 | `0100000` | |
| `ADD` `SUB` | R | `0110011` | 000 | `0000000`/`0100000` | |
| `SLL` `SLT` `SLTU` `XOR` `SRL` `SRA` `OR` `AND` | R | `0110011` | | | |
| `FENCE` | I | `0001111` | 000 | | treated as NOP |
| `ECALL` | I | `1110011` | 000 | imm=0 | monitor or trap |
| `EBREAK` | I | `1110011` | 000 | imm=1 | breakpoint halt |
| `CSRRW` `CSRRS` `CSRRC` `CSRRWI` `CSRRSI` `CSRRCI` | I | `1110011` | | | see CSR section |

Shifts mask the amount with `0x1f`. `FENCE` does not order anything the functional core would otherwise reorder, the functional core does not reorder. In OoO mode `FENCE` is a full pipeline drain: it occupies the ROB and does not commit until older loads and stores have committed. That is stronger than RV `FENCE` and weaker than `FENCE.I`; it is documented here so nobody thinks we implemented the Zifencei prefetch story.

### RV32M

| Mnemonic | funct3 | funct7 | Notes |
|---|---|---|---|
| `MUL` | 000 | `0000001` | low 32 of signed×signed |
| `MULH` | 001 | | high 32 of signed×signed |
| `MULHSU` | 010 | | high 32 of signed×unsigned |
| `MULHU` | 011 | | high 32 of unsigned×unsigned |
| `DIV` | 100 | | signed; see traps below |
| `DIVU` | 101 | | unsigned |
| `REM` | 110 | | signed remainder |
| `REMU` | 111 | | unsigned remainder |

Division edge cases, as specified:

- Division by zero: `DIV`/`DIVU` produce `0xFFFFFFFF`, `REM`/`REMU` produce the dividend.
- Signed overflow (`INT_MIN / -1`): `DIV` produces `INT_MIN`, `REM` produces `0`.

There is no divide-by-zero trap. RISC-V does not have one.

## Illegal encodings

Anything that decodes to an unimplemented opcode, a bad `funct3`/`funct7` pair, a reserved shift `funct7`, or a CSR address we do not know becomes an **illegal instruction** exception: `mcause = 2`, `mtval = inst`, `mepc = pc`.

We do **not** implement the “any `funct7` on shifts is OK if we ignore the extra bits” folklore. `SLLI`/`SRLI`/`SRAI` require the exact `funct7`. This matches the frozen spec and rejects garbage.

## Traps

| `mcause` | Meaning |
|---|---|
| 0 | instruction address misaligned (never for 32-bit insns on 4-byte PC; JALR to odd is aligned down, not trapped) |
| 1 | instruction access fault |
| 2 | illegal instruction |
| 3 | breakpoint (`EBREAK`) |
| 5 | load access fault |
| 7 | store access fault |
| 11 | environment call from M (`ECALL` when not handled by the monitor) |

`JALR` clears bit 0 of the target. An instruction fetch PC that is not 4-byte aligned after that (it will not happen for I-aligned encodings) would set cause 0. Compressed instructions are illegal (cause 2) rather than misaligned, because we do not implement C.

On trap:

```
mepc   = pc of faulting insn
mtval  = bad address or bad instruction
mcause = code above
if mtvec == 0: halt
else pc = mtvec          ; direct mode only. vectored mode is rejected at CSR write
```

`MRET` restores `pc = mepc`. We keep a 2-deep `mpp` stack in `mstatus` the cheap way: `MPP` is always M, `MPIE`/`MIE` swap on trap and `MRET`. Interrupts are modeled (CSRs exist) but no timer interrupt fires unless a test pokes `mip`.

## CSRs

Addresses are 12-bit. Writable CSRs update on `CSRRW` always, and on `CSRRS`/`CSRRC` when `rs1 != x0` (or when the immediate form has a non-zero uimm).

| Addr | Name | Access | Notes |
|---|---|---|---|
| `0x300` | `mstatus` | RW | bits `MIE=3`, `MPIE=7`, `MPP=12:11` |
| `0x304` | `mie` | RW | `MSIE`, `MTIE`, `MEIE` stored, not raised internally |
| `0x305` | `mtvec` | RW | bit 0 must be 0 (direct). write of vectored (`mode=1`) is illegal |
| `0x340` | `mscratch` | RW | |
| `0x341` | `mepc` | RW | bit 0 forced 0 |
| `0x342` | `mcause` | RW | |
| `0x343` | `mtval` | RW | |
| `0x344` | `mip` | RW | |
| `0xB00` | `mcycle` | RW | low 32 of the 64-bit counter |
| `0xB02` | `minstret` | RW | low 32 |
| `0xB80` | `mcycleh` | RW | high 32 |
| `0xB82` | `minstreth` | RW | high 32 |
| `0xC00` | `cycle` | RO | alias of `mcycle` |
| `0xC02` | `instret` | RO | alias of `minstret` |
| `0xC80` | `cycleh` | RO | |
| `0xC82` | `instreth` | RO | |
| `0xF11` | `mvendorid` | RO | `0` |
| `0xF12` | `marchid` | RO | `0` |
| `0xF13` | `mimpid` | RO | `0x504C4E4B` (`PLNK`) |
| `0xF14` | `mhartid` | RO | `0` |

`mcycle` in functional mode increments by 1 per retired instruction. In OoO mode it increments once per `ooo_tick`, including squash bubbles. That is the whole point of the timing model.

## Memory ordering as the guest sees it

RV32I has no `FENCE` semantics that a single-hart in-order core would violate. The OoO core:

- Retires loads and stores in program order at the ROB head.
- Allows loads to execute early if they pass the store-buffer search (address known, no overlap with an older store, or overlap with a *forwardable* older store of the same size).
- Replays a load if a store older in program order writes the same bytes after the load issued. That is the classic load-queue violation. Counted as `lsu.replay`.

No multi-hart, so there is no `FENCE` that publishes to another core.

## Ecall monitor

If `a7` matches a known service, `ECALL` is **not** an exception. It is handled at retire (functional: immediately; OoO: at commit) and writes `a0` as the return.

| `a7` | Name | Args | Effect |
|---|---|---|---|
| 0 | `exit` | `a0 = code` | halt host process with that code after flushing stats |
| 1 | `write` | `a0=fd, a1=buf, a2=len` | host `write`; `a0 = bytes or -errno` |
| 2 | `read` | `a0=fd, a1=buf, a2=len` | host `read` into guest memory |
| 3 | `cycle` | | `a0 = mcycle` (low 32) |
| 4 | `sbrk` | `a0 = increment` | bump heap, return old break in `a0` |
| 5 | `dump` | | print GPRs to host stderr (debug) |
| 93 | `exit` | `a0 = code` | Linux/RISC-V newlib convention, same as 0 |

Unknown `a7` raises exception 11 so a guest that thinks it is talking to Linux fails in a RISC-V-shaped way.

`write` only allows `fd` 1 and 2. Everything else returns `-EBADF`. This is a simulator, not a sandbox escape.

## Endianness and alignment

Little-endian. Loads and stores may be unaligned: they work, they are not fast. In the OoO model an unaligned access that spans a cache line is split into two line probes and pays both. Functional mode does not tax them. Alignment faults are not taken for data; instruction fetch still requires 2-byte alignment and we require 4 because C is off.

## Source of truth

`src/include/rv32.inc` is the machine-readable ISA. If this document and that file disagree, the file is what the decoder ran, and that is a documentation bug.
