# Diagrams

Collected mermaid for people who open this file first. Prose lives in the sibling documents.

## Host / guest cut

```mermaid
flowchart TB
  subgraph process["Linux process, statically linked, no libc"]
    subgraph host["x86-64 assembly"]
      start["_start / CLI"]
      arena["mmap arena"]
      asm["two-pass assembler"]
      fun["functional interpreter"]
      ooo["OoO timing model"]
      mon["ecall monitor"]
    end
    subgraph guest["RV32IM hart in the arena"]
      ram["guest RAM image"]
      gpr["x0..x31"]
      csr["mcycle minstret mtvec ..."]
    end
  end
  start --> arena --> asm --> ram
  fun --> gpr
  ooo --> gpr
  fun --> ram
  ooo --> ram
  fun --> mon
  ooo --> mon
  mon -->|write/exit| start
```

## One OoO cycle

```mermaid
flowchart TD
  A[1 commit ≤2] --> B[2 writeback FUs / loads]
  B --> C[3 issue ready RS → FU]
  C --> D[4 rename / dispatch ≤2]
  D --> E[5 decode ≤2]
  E --> F[6 fetch ≤2 with pred + I$]
  F --> G{squash flag?}
  G -->|yes| H[walk ROB young→old, restore map_s, redirect PC]
  G -->|no| I[mcycle++]
  H --> I
```

## Mispredict

```mermaid
sequenceDiagram
  participant F as fetch
  participant P as tournament+BTB
  participant R as ROB
  participant B as branch FU
  participant M as map_s

  F->>P: PC
  P-->>F: pred NPC
  F->>R: dispatch branch with pred_npc
  Note over R: younger ops dispatch
  B->>B: execute, actual NPC
  B->>R: complete, maybe mispred
  alt mispred
    R->>M: squash younger, map_s = old_preg
    R->>F: PC = actual NPC
  else ok
    R->>R: commit in order
  end
```

## Store forwarding

```mermaid
flowchart TD
  L[load addr ready] --> S[scan SB youngest older]
  S --> Q{older ST addr known?}
  Q -->|no| W[block load]
  Q -->|yes overlap bad size| R[replay]
  Q -->|yes exact match data rdy| F[forward, skip D$]
  Q -->|yes no overlap| N[next older]
  N --> S
  S -->|none| D[L1D probe]
```

## Cache fill with MSHR merge

```mermaid
flowchart LR
  A[load miss line X] --> M{MSHR free?}
  M -->|slot to X exists| J[join waiters]
  M -->|free slot| F[alloc, remaining = L2 or DRAM lat]
  M -->|full| S[LSU stall]
  F --> T[each tick remaining--]
  T -->|0| I[install line, wakeup]
  J --> T
```

## `li` expansion

```mermaid
flowchart TD
  I[li rd, imm] --> A{fits 12-bit signed?}
  A -->|yes| B[addi rd, x0, imm]
  A -->|no| C[lo = sext12 imm]
  C --> D[hi = imm - lo, then >> 12]
  D --> E[lui rd, hi]
  E --> F{lo == 0?}
  F -->|yes| G[done]
  F -->|no| H[addi rd, rd, lo]
```

## Test cross-check

```mermaid
flowchart LR
  S[.s source] --> AS[assembler]
  AS --> IMG[raw image]
  IMG --> F[functional halt]
  IMG --> O[OoO halt]
  F --> C{regs + RAM fold}
  O --> C
  C -->|equal| OK[ok]
  C -->|not| BAD[FAIL + ROB trace]
```

## Predictor update at commit

```mermaid
flowchart TD
  BR[committed branch] --> O[actual taken?]
  O --> BIM[update bimodal]
  O --> GS[update gshare]
  O --> GHR[shift GHR]
  BIM --> CMP{who was right?}
  GS --> CMP
  CMP -->|only bim| CH1[chooser toward bim]
  CMP -->|only gshare| CH2[chooser toward gshare]
  CMP -->|tie| Z[no chooser update]
  O --> BTB[write target / kind]
  BR --> RAS[push or pop already done at dispatch; squash repairs]
```

## Assembler encode (where operands live)

```mermaid
flowchart LR
  P[parse_reg / parse_imm] --> BSS["BSS op_rd op_rs1 op_rs2 op_imm"]
  BSS --> PK[pack_r/i/s/b/u/j]
  PK --> MEM[img_buf little-endian]
  subgraph clobber["do not stash here"]
    R8[r8 = reg_lookup index]
    H[r8 = hash_get slot]
  end
  P -.-> clobber
```

`add t4, t0, t1` must pack `rd=29, rs1=5, rs2=6`. If `rd` is left in `r8` across the last `parse_reg`, it becomes `6` and the guest sees `add t1, t0, t1` — or, worse, an illegal encoding.

## Guest program map

```mermaid
flowchart TB
  RST[0x80000000 reset] --> T[text: programs/*.s]
  T --> D[.word / .ascii / .space]
  T --> SP[sp = mem_top - 16]
  T --> E[ecall a7=0 → host exit a0]
```

