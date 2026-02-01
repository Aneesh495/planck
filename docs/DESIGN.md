# Design notes

Decisions that do not belong in the architecture spec but will otherwise get relitigated in review.

## Why RISC-V and not x86 guest

x86 decode is a project by itself. RV32 is a 32-bit word with five formats. The interesting bugs I wanted were in rename and the LSU, not in `modrm`. RISC-V is also what a quant FPGA team and a FAANG NPU team will both read without a decoder cheat sheet.

## Why the simulator is assembly

Two reasons, only one of which is the résumé.

1. **The host data layout is the product.** A C `struct cpu` hides padding, ABI, and the fact that the ROB scan is a `rep`-unfriendly 64-byte stride. Writing the offsets by hand is the same work a kernel person does for `task_struct`.
2. **No accidental calls.** A C simulator of an OoO core will malloc in a surprising place, print with stdio in a trap path, and pull in glibc's `memcpy` AVX path which then dominates `perf`. Planck's hot path is a known set of functions.

The second reason is why `--stats` reports host TSC separately. If the model is slow, that is our loop, not `printf`.

## Why 2-wide, not 8-wide

An 8-wide ROB scan in assembly is a nested mess and a lie unless you also write a selection network. 2-wide is the BOOM “small core” / Cortex-A53 neighbourhood: enough for IPC > 1 on real code, small enough that `pipeline.asm` fits in a reviewer's working memory.

## Why committed-history GHR

Speculative GHR is more accurate on `dhrystone` and a pain on squash. The first core trains at commit. If a later patch adds speculative GHR it must checkpoint 12 bits in the ROB entry. The field is already there (`ras_tos` packed with a spare) and unused for that.

## Why inclusive L2

Exclusive L2 is more capacity. Inclusive L2 is a single answer to “is this line in the hierarchy.” Back-invalidates are implemented, which is the part people skip. Inclusive was the way to force that code to exist.

## Why not RV32C

Compressed instructions double the fetch alignment story and the disassembler. They hide the 32-bit encodings this repository is trying to show. Illegal on purpose.

## Why not ELF

ELF is a weekend. A raw image at `0x80000000` is an honest assembler. `call` far expansions are the reloc story we actually needed.

## Why functional mode ignores the cache

Golden models that go through a cache are golden models with extra bugs. Functional load/store is a bounds-checked memcpy against the mmap. OoO must match it at halt. Cache tests are unit tests against the cache API.

## Why `x` registers are qwords

Every sign-extension path used to be a mix of `movsxd`, `cdqe`, and accidental 64-bit `sar`. Storing 32-bit values in the low half of qwords, with the high half always zero except inside a sign-extend helper, made `MULH` reviewable.

## Why a bump allocator

Freeing individual ROB entries into malloc is how you discover your simulator's IPC is `malloc_consolidate`. The arena dies at process exit. Tests call `arena_reset`.

## Scaling knobs vs honesty

`ooo.inc` has the widths. Raising ROB to 256 without changing the scheduler from “linear scan” makes `--stats` look like a bigger core and `rdtsc` look like a worse simulator. If you change the knobs, change the comments in `MICROARCHITECTURE.md` in the same commit.

## Related work, unpaid

- Spike and QEMU for the ISA questions.
- BOOM / SonicBOOM for the “small OoO RISC-V” shape.
- Hennessy & Patterson, Appendix C, for the tournament predictor.
- *The RISC-V Reader* for the encodings we retyped into `rv32.inc`.

None of those are in assembly. That is the gap.
