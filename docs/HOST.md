# Host ABI

The host is a freestanding x86-64 Linux executable. The linker script is “there is no linker script”: `ld -static -nostdlib` with `_start` in `src/host/start.asm`.

## Syscalls used

| rax | name | use |
|---|---|---|
| 0 | `read` | `--` guest `ecall` read, and reading source files |
| 1 | `write` | stdout stats, stderr errors, guest write |
| 3 | `close` | after `openat` |
| 8 | `lseek` | `asm` file size |
| 9 | `mmap` | one arena |
| 11 | `munmap` | atexit-ish, also on `host_die` |
| 60 | `exit` | `_exit` |
| 228 | `clock_gettime` | optional wall clock next to `rdtsc` |
| 257 | `openat` | `AT_FDCWD`, source and image files |

No `brk`. No `ioctl`. No `writev`. Formatting is userspace into a 4 KiB scratch buffer, then one `write`.

`mmap` flags: `MAP_PRIVATE | MAP_ANONYMOUS`. Prot: `READ | WRITE`. The arena is not `MAP_HUGETLB` by default; a comment in `mem.asm` says how to turn it on if you have pages.

## Calling convention (host)

System V AMD64, because NASM `call` to our own functions should look like every other Linux binary if we ever grow a C test harness (we did not).

- Args: `rdi, rsi, rdx, rcx, r8, r9`
- Volatile: `rax, rcx, rdx, rsi, rdi, r8-r11`
- Callee-saved: `rbx, rbp, r12-r15`
- Return: `rax` (value or negative `-errno` for host I/O wrappers)
- Stack 16-byte aligned at `call`

Booleans are 0 / 1 in `eax`, not flags, unless the function is documented as “ZF means miss.” Cache probes return ZF miss for compactness on the LSU path. That is the only flag-return.

## Arena

```
arena_init(size) -> pointer, also stored in [g_arena]
arena_alloc(bytes, align) -> pointer        ; bump, never free
arena_reset()                               ; only between tests
```

Bump pointer is 8-byte aligned at minimum. `cpu_init` asks for the CPU, then ROB, RS arrays, predictor tables, cache tag arrays, guest RAM, in that order. Tests that run back-to-back call `arena_reset` and `cpu_init` again.

OOM: if the bump would exceed the mapping, `host_die("arena: out of memory")`. Size is `cpu_struct + 64MiB RAM + ~2MiB tables` by default, mapping 80 MiB to have slack.

## Formatting

`src/host/io.asm` is a tiny stdio:

- `io_write(fd, buf, len)`
- `io_cstr(fd, zstring)`
- `io_u64(fd, val, width, base)` — base 10 or 16, width 0 means no pad
- `io_i64` — sign then `io_u64`
- `io_hex32` — `0x` + 8 digits
- `io_nl`, `io_sp`, `io_chr`

No printf. A stats line is a sequence of those calls. That is annoying to write and impossible to format-string inject.

## Hashmap

`src/host/hash.asm`. Open addressing, FNV-1a 64 of a byte string, linear probe, tombstones for delete (assembler does not delete; the API still has it).

```
hash_init(map, cap_pow2, arena)
hash_put(map, key, keylen, val) -> 0 ok, -1 full
hash_get(map, key, keylen, *val) -> 0 hit, -1 miss
```

Used for labels and `.equ`. Cap starts at 1024. `hash_grow` allocates 2x from the arena and reinserts. Old table is leaked in arena terms — bump allocators do that. Assembler runs once per process in `run`, many times in `test`; tests `arena_reset`.

## Time

`rdtsc` is serialized with `lfence` before and `lfence` after the measured region, not `rdtscp` + `cpuid` (cpuid is a VM exit on some hosts and makes the histogram about the hypervisor). Histogram is a 64-bucket log2 of cycle deltas for `ooo_tick` and for `interp_step`, so you can see tail behavior of the *simulator*.

`clock_gettime(CLOCK_MONOTONIC)` is used only in `bench` for a human-readable ns number next to TSC.

## CLI parsing

`start.asm` walks `argv`. Flags are exact matches (`--mode`, `--stats`, …). Unknown flags die. `--mode ooo` and `--mode functional` are the only modes. `--mem` accepts `64m`, `64M`, `67108864`.

## Files vs guest

`host_read_file(path, *ptr, *len)` allocates a buffer from the arena, reads the whole file. Max source 2 MiB. The assembler holds pointers into that buffer; it does not copy lines.

## Die

```
host_die(msg):
  write(2, "planck: ", 8)
  write(2, msg, strlen)
  write(2, "\n", 1)
  exit(1)
```

No unwind. Guest traps that halt without `mtvec` go through `cpu_halt_dump`, which is not `host_die`: exit code is 0 if the guest `ecall exit 0`, 1 if a fault, or the guest code.
