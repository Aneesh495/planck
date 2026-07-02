# Layout

Byte offsets of host structures. Source of truth: `src/include/*.inc`. This file is the readable copy for reviewers who do not want to open NASM.

All offsets are decimal. Pointers are 8 bytes. Guest values stored in qwords are zero-extended RV32.

## `cpu_t`  (`include/cpu.inc`)

| Off | Size | Name |
|---|---|---|
| 0 | 256 | `x[32]` qwords |
| 256 | 8 | `pc` |
| 264 | 8 | `mcycle` |
| 272 | 8 | `minstret` |
| 280 | 8 | `mem_base` host pointer |
| 288 | 8 | `mem_size` |
| 296 | 8 | `heap_brk` guest address |
| 304 | 8 | `stack_top` guest address |
| 312 | 4 | `halt` |
| 316 | 4 | `halt_code` |
| 320 | 4 | `priv` |
| 324 | 4 | `mode` 0 functional 1 ooo |
| 328 | 4 | `trap_pending` |
| 332 | 4 | `pad` |
| 336 | 8 | `mstatus` |
| 344 | 8 | `mie` |
| 352 | 8 | `mtvec` |
| 360 | 8 | `mscratch` |
| 368 | 8 | `mepc` |
| 376 | 8 | `mcause` |
| 384 | 8 | `mtval` |
| 392 | 8 | `mip` |
| 400 | 8 | `arena` back-pointer |
| 408 | 8 | `l1i` |
| 416 | 8 | `l1d` |
| 424 | 8 | `l2` |
| 432 | 8 | `itlb` |
| 440 | 8 | `dtlb` |
| 448 | 8 | `pred` |
| 456 | 8 | `ooo` |
| 464 | 8 | `stats` |
| 472 | 8 | `trace_ring` |
| 480 | 8 | `fetch_pc` |
| 488 | 4 | `squash` |
| 492 | 4 | `pad2` |
| 496 | 8 | `squash_pc` |
| 504 | 8 | `entry_pc` |
| 512 | 8 | `max_inst` |
| 520 | 8 | `max_cycle` |
| 528 | 4 | `flags` (trace / stats / dump_regs) |
| 532 | 4 | pad |
| 536 | 4 | `trace_len` |
| 540 | 4 | `trace_cap` |
| 576 | | `CPU_SIZE` |

`x0` lives at offset 0 and is rewritten to 0 after every writeback helper.

## `dec_t`  (`include/rv32.inc`)

| Off | Size | Name |
|---|---|---|
| 0 | 4 | `raw` |
| 4 | 4 | `pc` |
| 8 | 4 | `id` internal opcode |
| 12 | 4 | `rd` |
| 16 | 4 | `rs1` |
| 20 | 4 | `rs2` |
| 24 | 4 | `imm` |
| 28 | 4 | `csr` |
| 32 | 4 | `pred_taken` |
| 36 | 4 | `pred_npc` |
| 40 | 4 | `size` always 4 |
| 44 | 4 | `illegal` |

## ROB entry  (`include/ooo.inc`)  64 bytes

| Off | Size | Name |
|---|---|---|
| 0 | 4 | `valid` |
| 4 | 4 | `complete` |
| 8 | 4 | `rd` |
| 12 | 4 | `dst_preg` |
| 16 | 4 | `old_preg` |
| 20 | 4 | `pc` |
| 24 | 4 | `npc` |
| 28 | 4 | `pred_npc` |
| 32 | 4 | `val` |
| 36 | 4 | `id` |
| 40 | 4 | `exc` |
| 44 | 4 | `exc_cause` |
| 48 | 4 | `is_store` |
| 52 | 4 | `is_br` |
| 56 | 4 | `mispred` |
| 60 | 4 | `ras_tos` |

## RS entry  64 bytes

| Off | Size | Name |
|---|---|---|
| 0 | 4 | `valid` |
| 4 | 4 | `rob_idx` |
| 8 | 4 | `op` |
| 12 | 4 | `dst_preg` |
| 16 | 4 | `s1` |
| 20 | 4 | `s1_tag` |
| 24 | 4 | `s1_rdy` |
| 28 | 4 | `s2` |
| 32 | 4 | `s2_tag` |
| 36 | 4 | `s2_rdy` |
| 40 | 4 | `imm` |
| 44 | 4 | `pc` |
| 48 | 4 | `pred_npc` |
| 52 | 4 | `fu_lat` |
| 56 | 4 | `issued` |
| 60 | 4 | `pad` |

## Cache line tags

Per line: `{tag:32, valid:8, dirty:8, lru:16}` packed in 8 bytes, plus a pointer into a data backing store of `sets * ways * 64` bytes. L1D data is real bytes (the guest RAM is not copied; L1D holds a copy for timing, and we *also* write through to guest RAM at **commit** so functional and OoO share one memory image). See [`MEMORY.md`](MEMORY.md) for why write-back still updates RAM at commit: the golden model would otherwise diverge on stores the cache had not flushed.

Clarification that the code follows: **architecturally committed stores update guest RAM immediately at commit, and the L1D line is updated then too.** Write-back policy is about *eviction traffic to L2* in the timing model, not about hiding stores from the architectural image. The simulator is not a coherence torture stand.

## Cache set

`way[WAYS]` of tag records, plus `mshr[N]`.

## Predictor

| Object | Size |
|---|---|
| bimodal | 4096 bytes (4 K packed 2-bit in 4-per-byte, actually 1 KB; we spend 4 K of bytes as 4 K counters of 8-bit for sanity) |
| gshare | same |
| chooser | same |
| GHR | 4 bytes |
| BTB | 128 * 16 = 2048 bytes |
| RAS | 16 * 4 + TOS |

2-bit counters stored as bytes 0..3. Wasteful. Clear. Do not pack nybbles unless you are writing a paper on it.

## Guest memory map (default 64 MiB)

| Guest | Contents |
|---|---|
| `0x80000000` | reset, `.text` |
| `0x80010000` | conventional `.data` if programs `.org` it |
| `0x80100000` | heap (`sbrk`) |
| `0x83FFF000` | stack top minus a page, approximately, for 64 MiB |

Exact stack top is `0x80000000 + mem_size - 16`.
