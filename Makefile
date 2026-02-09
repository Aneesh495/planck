# Planck — Linux x86-64, NASM, no libc.
# On Apple Silicon: `docker build --platform linux/amd64`.

NASM      ?= nasm
LD        ?= ld
NASMFLAGS ?= -f elf64 -g -F dwarf -I src/include/ -Wall
LDFLAGS   ?= -static -nostdlib -z noexecstack

SRC_HOST = \
	src/host/syscall.asm \
	src/host/die.asm \
	src/host/string.asm \
	src/host/io.asm \
	src/host/mem.asm \
	src/host/hash.asm \
	src/host/time.asm \
	src/host/file.asm

SRC_CORE =
SRC_ASM  =
SRC_DIS  =
SRC_CACHE=
SRC_PRED =
SRC_OOO  =
SRC_STAT =
SRC_MON  =
SRC_TEST =
SRC_MAIN =

SRCS = $(SRC_HOST) $(SRC_CORE) $(SRC_ASM) $(SRC_DIS) $(SRC_CACHE) \
       $(SRC_PRED) $(SRC_OOO) $(SRC_STAT) $(SRC_MON) $(SRC_TEST) $(SRC_MAIN)

OBJS = $(patsubst src/%.asm,obj/%.o,$(filter src/%,$(SRCS))) \
       $(patsubst tests/%.asm,obj/tests/%.o,$(filter tests/%,$(SRCS)))

.PHONY: all clean lines dirs

all: dirs
	@echo "host runtime objects only — link once src/host/start.asm exists"
	@$(MAKE) --no-print-directory objects

objects: $(OBJS)

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

clean:
	rm -rf obj bin

lines:
	@echo -n "asm lines: "
	@find src tests programs -name '*.asm' -o -name '*.s' -o -name '*.inc' 2>/dev/null | xargs wc -l | tail -1
