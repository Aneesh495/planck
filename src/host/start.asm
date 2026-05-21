; src/host/start.asm
; _start: argv walk, commands run/asm/disasm/test/bench/version.

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"
%include "abi.inc"
%include "cpu.inc"

        extern arena_create
        extern arena_destroy
        extern host_die
        extern host_exit
        extern host_read_file
        extern host_write_file
        extern sys_write
        extern str_cmp
        extern str_len
        extern str_ncmp
        extern io_cstr
        extern io_nl
        extern io_dec
        extern io_hex32
        extern io_udec
        extern io_sp
        extern cpu_create
        extern cpu_reset
        extern cpu_get_x
        extern interp_run
        extern asm_compile
        extern disasm_image
        extern mem_cpy
        extern stats_report

        section .rodata
usage:  db "usage: planck <run|asm|disasm|test|bench|version> [file] [--mode functional|ooo] [--stats] [--trace] [--dump-regs]",10,0
ver:    db "planck 0.1.0  RV32IM functional+OoO  no libc",10,0
banner: db "planck: halt reason=",0
code_s: db " code=",0
inst_s: db " instret=",0
cyc_s:  db " mcycle=",0
ok_s:   db "test: not yet linked (build with tests)",10,0
err_cmd:db "unknown command",0
err_file:db "missing file",0
err_mode:db "bad --mode",0

cmd_run:        db "run",0
cmd_asm:        db "asm",0
cmd_dis:        db "disasm",0
cmd_test:       db "test",0
cmd_bench:      db "bench",0
cmd_ver:        db "version",0
cmd_help:       db "help",0
fl_mode:        db "--mode",0
fl_stats:       db "--stats",0
fl_trace:       db "--trace",0
fl_dump:        db "--dump-regs",0
fl_o:           db "-o",0
mode_fun:       db "functional",0
mode_ooo:       db "ooo",0

        section .bss
        align 8
out_ptr:        resq 1
out_len:        resq 1
g_cpu:          resq 1
g_file:         resq 1
g_ofile:        resq 1
g_mode:         resd 1
g_flags:        resd 1
g_argc:         resd 1
g_argv:         resq 1

        section .text

PROC _start
        mov     rax, [rsp]
        mov     [rel g_argc], eax
        lea     rsi, [rsp+8]
        mov     [rel g_argv], rsi
        ; 80 MiB arena
        mov     rdi, DEFAULT_ARENA
        call    arena_create
        mov     rdi, [rel g_argv]
        mov     eax, [rel g_argc]
        cmp     eax, 2
        jl      .usage
        mov     rsi, [rdi + 8]          ; argv[1]
        mov     rdi, rsi
        lea     rsi, [rel cmd_run]
        call    str_cmp
        test    eax, eax
        jz      cmd_run_fn
        mov     rdi, [rel g_argv]
        mov     rdi, [rdi + 8]
        lea     rsi, [rel cmd_asm]
        call    str_cmp
        test    eax, eax
        jz      cmd_asm_fn
        mov     rdi, [rel g_argv]
        mov     rdi, [rdi + 8]
        lea     rsi, [rel cmd_dis]
        call    str_cmp
        test    eax, eax
        jz      cmd_dis_fn
        mov     rdi, [rel g_argv]
        mov     rdi, [rdi + 8]
        lea     rsi, [rel cmd_test]
        call    str_cmp
        test    eax, eax
        jz      cmd_test_fn
        mov     rdi, [rel g_argv]
        mov     rdi, [rdi + 8]
        lea     rsi, [rel cmd_bench]
        call    str_cmp
        test    eax, eax
        jz      cmd_bench_fn
        mov     rdi, [rel g_argv]
        mov     rdi, [rdi + 8]
        lea     rsi, [rel cmd_ver]
        call    str_cmp
        test    eax, eax
        jz      cmd_ver_fn
        mov     rdi, [rel g_argv]
        mov     rdi, [rdi + 8]
        lea     rsi, [rel cmd_help]
        call    str_cmp
        test    eax, eax
        jz      .usage
        lea     rdi, [rel err_cmd]
        call    host_die

.usage:
        mov     edi, 2
        lea     rsi, [rel usage]
        call    io_cstr
        xor     edi, edi
        call    host_exit

cmd_ver_fn:
        mov     edi, 1
        lea     rsi, [rel ver]
        call    io_cstr
        xor     edi, edi
        call    host_exit

cmd_test_fn:
        extern planck_test
        call    planck_test
        mov     edi, eax
        call    host_exit

cmd_bench_fn:
        ; assemble a tiny loop internally later; for now version-like
        jmp     cmd_ver_fn

; parse flags from argv[2..]
parse_flags:
        push    rbx
        push    r12
        mov     r12d, 2                 ; index
        mov     dword [rel g_mode], MODE_FUNCTIONAL
        mov     dword [rel g_flags], 0
        mov     qword [rel g_file], 0
        mov     qword [rel g_ofile], 0
.loop:
        cmp     r12d, [rel g_argc]
        jge     .done
        mov     rax, [rel g_argv]
        mov     ebx, r12d
        mov     rdi, [rax + rbx*8]
        lea     rsi, [rel fl_mode]
        call    str_cmp
        test    eax, eax
        jz      .mode
        mov     rax, [rel g_argv]
        mov     rdi, [rax + rbx*8]
        lea     rsi, [rel fl_stats]
        call    str_cmp
        test    eax, eax
        jz      .stats
        mov     rax, [rel g_argv]
        mov     rdi, [rax + rbx*8]
        lea     rsi, [rel fl_trace]
        call    str_cmp
        test    eax, eax
        jz      .trace
        mov     rax, [rel g_argv]
        mov     rdi, [rax + rbx*8]
        lea     rsi, [rel fl_dump]
        call    str_cmp
        test    eax, eax
        jz      .dump
        mov     rax, [rel g_argv]
        mov     rdi, [rax + rbx*8]
        lea     rsi, [rel fl_o]
        call    str_cmp
        test    eax, eax
        jz      .ofile
        ; positional file
        mov     rax, [rel g_argv]
        mov     rax, [rax + rbx*8]
        mov     [rel g_file], rax
        inc     r12d
        jmp     .loop
.mode:
        inc     r12d
        cmp     r12d, [rel g_argc]
        jge     .badmode
        mov     rax, [rel g_argv]
        mov     ebx, r12d
        mov     rdi, [rax + rbx*8]
        lea     rsi, [rel mode_fun]
        call    str_cmp
        test    eax, eax
        jz      .fun
        mov     rax, [rel g_argv]
        mov     rdi, [rax + rbx*8]
        lea     rsi, [rel mode_ooo]
        call    str_cmp
        test    eax, eax
        jnz     .badmode
        mov     dword [rel g_mode], MODE_OOO
        inc     r12d
        jmp     .loop
.fun:
        mov     dword [rel g_mode], MODE_FUNCTIONAL
        inc     r12d
        jmp     .loop
.stats:
        or      dword [rel g_flags], CPUF_STATS
        inc     r12d
        jmp     .loop
.trace:
        or      dword [rel g_flags], CPUF_TRACE
        inc     r12d
        jmp     .loop
.dump:
        or      dword [rel g_flags], CPUF_DUMP
        inc     r12d
        jmp     .loop
.ofile:
        inc     r12d
        mov     rax, [rel g_argv]
        mov     ebx, r12d
        mov     rax, [rax + rbx*8]
        mov     [rel g_ofile], rax
        inc     r12d
        jmp     .loop
.badmode:
        lea     rdi, [rel err_mode]
        call    host_die
.done:
        pop     r12
        pop     rbx
        ret

load_and_asm:
        ; uses g_file → out_ptr, out_len
        mov     rdi, [rel g_file]
        test    rdi, rdi
        jnz     .ok
        lea     rdi, [rel err_file]
        call    host_die
.ok:
        lea     rsi, [rel out_ptr]
        lea     rdx, [rel out_len]
        ; host_read_file overwrites out_ptr with SOURCE. Keep source separate.
        ; We'll store source in out_ptr then compile into new buffers.
        call    host_read_file
        ; now out_ptr = source, out_len = slen
        mov     rdi, [rel out_ptr]
        mov     rsi, [rel out_len]
        mov     rdx, [rel g_file]
        lea     rcx, [rel out_ptr]
        ; PROBLEM: we overwrite source pointer. Save source first.
        ret

; fixed load: keep source in r12 locally in callers

cmd_run_fn:
        call    parse_flags
        mov     rdi, [rel g_file]
        test    rdi, rdi
        jnz     .f
        lea     rdi, [rel err_file]
        call    host_die
.f:
        sub     rsp, 32
        lea     rsi, [rsp]              ; src**
        lea     rdx, [rsp+8]            ; len*
        mov     rdi, [rel g_file]
        call    host_read_file
        mov     rdi, [rsp]
        mov     rsi, [rsp+8]
        mov     rdx, [rel g_file]
        lea     rcx, [rsp+16]           ; img**
        lea     r8, [rsp+24]            ; imglen*
        call    asm_compile
        mov     rdi, DEFAULT_MEM_SIZE
        mov     esi, [rel g_mode]
        call    cpu_create
        mov     [rel g_cpu], rax
        mov     eax, [rel g_flags]
        mov     rcx, [rel g_cpu]
        mov     [rcx + CPU_FLAGS], eax
        ; copy image
        mov     rdi, [rcx + CPU_MEM_BASE]
        mov     rsi, [rsp+16]
        mov     rdx, [rsp+24]
        cmp     rdx, DEFAULT_MEM_SIZE
        jb      .cpy
        lea     rdi, [rel err_file]
        call    host_die
.cpy:
        call    mem_cpy
        mov     rdi, [rel g_cpu]
        cmp     dword [rdi + CPU_MODE], MODE_OOO
        je      .ooo
        call    interp_run
        jmp     .halt
.ooo:
        extern ooo_run
        call    ooo_run
.halt:
        mov     rbx, [rel g_cpu]
        mov     edi, 1
        lea     rsi, [rel banner]
        call    io_cstr
        mov     edi, 1
        mov     esi, [rbx + CPU_HALT]
        xor     edx, edx
        mov     ecx, 10
        call    io_udec
        mov     edi, 1
        lea     rsi, [rel code_s]
        call    io_cstr
        mov     edi, 1
        mov     esi, [rbx + CPU_HALT_CODE]
        call    io_dec
        mov     edi, 1
        lea     rsi, [rel inst_s]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [rbx + CPU_MINSTRET]
        call    io_udec
        mov     edi, 1
        lea     rsi, [rel cyc_s]
        call    io_cstr
        mov     edi, 1
        mov     rsi, [rbx + CPU_MCYCLE]
        call    io_udec
        mov     edi, 1
        call    io_nl
        test    dword [rbx + CPU_FLAGS], CPUF_STATS
        jz      .nostats
        mov     rdi, rbx
        call    stats_report
.nostats:
        test    dword [rbx + CPU_FLAGS], CPUF_DUMP
        jz      .nodump
        extern monitor_ecall
        ; dump via ecall helper: print x0..x31
        xor     r12d, r12d
.dloop:
        cmp     r12d, 32
        jge     .nodump
        mov     rdi, rbx
        mov     esi, r12d
        call    cpu_get_x
        push    rax
        mov     edi, 1
        mov     esi, r12d
        xor     edx, edx
        mov     ecx, 10
        call    io_udec
        mov     edi, 1
        call    io_sp
        pop     rsi
        mov     edi, 1
        call    io_hex32
        mov     edi, 1
        call    io_nl
        inc     r12d
        jmp     .dloop
.nodump:
        mov     edi, [rbx + CPU_HALT_CODE]
        add     rsp, 32
        call    host_exit
        ret

cmd_asm_fn:
        call    parse_flags
        mov     rdi, [rel g_file]
        test    rdi, rdi
        jnz     .f
        lea     rdi, [rel err_file]
        call    host_die
.f:
        sub     rsp, 32
        mov     rdi, [rel g_file]
        lea     rsi, [rsp]
        lea     rdx, [rsp+8]
        call    host_read_file
        mov     rdi, [rsp]
        mov     rsi, [rsp+8]
        mov     rdx, [rel g_file]
        lea     rcx, [rsp+16]
        lea     r8, [rsp+24]
        call    asm_compile
        mov     rdi, [rel g_ofile]
        test    rdi, rdi
        jnz     .wr
        ; disasm to stdout
        mov     edi, 1
        mov     rsi, [rsp+16]
        mov     rdx, [rsp+24]
        mov     ecx, GUEST_RESET
        call    disasm_image
        add     rsp, 32
        xor     edi, edi
        call    host_exit
.wr:
        mov     rsi, [rsp+16]
        mov     rdx, [rsp+24]
        call    host_write_file
        add     rsp, 32
        xor     edi, edi
        call    host_exit

cmd_dis_fn:
        call    parse_flags
        mov     rdi, [rel g_file]
        sub     rsp, 16
        lea     rsi, [rsp]
        lea     rdx, [rsp+8]
        call    host_read_file
        mov     edi, 1
        mov     rsi, [rsp]
        mov     rdx, [rsp+8]
        mov     ecx, GUEST_RESET
        call    disasm_image
        add     rsp, 16
        xor     edi, edi
        call    host_exit
