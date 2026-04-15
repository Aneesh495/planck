# Planck — Linux x86-64, NASM, no libc.
# Apple Silicon: docker build --platform linux/amd64.

NASM      ?= nasm
LD        ?= ld
NASMFLAGS ?= -f elf64 -g -F dwarf -I src/include/ -Wall
LDFLAGS   ?= -static -nostdlib -z noexecstack

SRC_HOST = \
	src/host/start.asm \
	src/host/syscall.asm \
	src/host/die.asm \
	src/host/string.asm \
	src/host/io.asm \
	src/host/mem.asm \
	src/host/hash.asm \
	src/host/time.asm \
	src/host/file.asm

SRC_CORE = \
	src/core/cpu.asm \
	src/core/bits.asm \
	src/core/decode.asm \
	src/core/trap.asm \
	src/core/csr.asm \
	src/core/exec.asm \
	src/core/exec_alu.asm \
	src/core/exec_mem.asm \
	src/core/exec_br.asm \
	src/core/exec_m.asm \
	src/core/exec_sys.asm \
	src/core/interp.asm

SRC_ASM = \
	src/asm/lexer.asm \
	src/asm/tables.asm \
	src/asm/compile.asm

SRC_DIS = src/disasm/disasm.asm

SRC_CACHE = src/cache/cache.asm

SRC_PRED = src/predict/predict.asm

SRC_OOO = \
	src/ooo/fu.asm \
	src/ooo/pipeline.asm

SRC_STAT = src/stats/report.asm

SRC_MON = src/monitor/ecall.asm

SRC_TEST = \
	tests/harness.asm \
	tests/test_hash.asm \
	tests/test_decode.asm \
	tests/test_alu.asm \
	tests/test_m.asm \
	tests/test_mem.asm \
	tests/test_branch.asm \
	tests/test_asm.asm \
	tests/test_cache.asm \
	tests/test_programs.asm

SRCS = $(SRC_HOST) $(SRC_CORE) $(SRC_ASM) $(SRC_DIS) $(SRC_CACHE) \
       $(SRC_PRED) $(SRC_OOO) $(SRC_STAT) $(SRC_MON) $(SRC_TEST)

OBJS = $(patsubst src/%.asm,obj/%.o,$(filter src/%,$(SRCS))) \
       $(patsubst tests/%.asm,obj/tests/%.o,$(filter tests/%,$(SRCS)))

.PHONY: all clean lines dirs test

all: dirs bin/planck

dirs:
	@mkdir -p bin obj/host obj/core obj/asm obj/disasm obj/cache \
	          obj/predict obj/ooo obj/stats obj/monitor obj/tests

obj/%.o: src/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) -o $@ $<

obj/tests/%.o: tests/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) -o $@ $<

bin/planck: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

test: all
	./bin/planck test

clean:
	rm -rf obj bin

lines:
	@echo "NASM + guest sources:"
	@find src tests programs -name '*.asm' -o -name '*.s' -o -name '*.inc' | sort | xargs wc -l
