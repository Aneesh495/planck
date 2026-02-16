; src/core/cpu.asm
; Architectural state: construction, reset, GPR access, x0 hardwire.

        bits 64
        default rel

%include "macros.inc"
%include "cpu.inc"
%include "abi.inc"
%include "stats.inc"
%include "rv32.inc"

        extern arena_alloc
        extern mem_set
        extern guest_store_u32

        section .text

; cpu_t *cpu_create(uint64 mem_size, uint32 mode)
PROC cpu_create
        push    rbx
        push    r12
        push    r13
        mov     r12, rdi                ; mem_size
        mov     r13d, esi               ; mode
        mov     edi, CPU_SIZE
        mov     esi, 64
        call    arena_alloc
        mov     rbx, rax                ; cpu
        mov     [rbx + CPU_MEM_SIZE], r12
        mov     [rbx + CPU_MODE], r13d
        mov     rdi, r12
        mov     esi, 4096
        call    arena_alloc
        mov     [rbx + CPU_MEM_BASE], rax
        mov     edi, ST_SIZE
        mov     esi, 8
        call    arena_alloc
        mov     [rbx + CPU_STATS], rax
        mov     edi, TRACE_RING_CAP * TRACE_ENT_SIZE
        mov     esi, 8
        call    arena_alloc
        mov     [rbx + CPU_TRACE], rax
        mov     dword [rbx + CPU_TRACE_CAP], TRACE_RING_CAP
        mov     rdi, rbx
        call    cpu_reset
        mov     rax, rbx
        pop     r13
        pop     r12
        pop     rbx
        ret

; void cpu_reset(cpu*)
PROC cpu_reset
        push    rbx
        mov     rbx, rdi
        ; zero GPRs
        lea     rdi, [rbx + CPU_X]
        xor     esi, esi
        mov     edx, 256
        call    mem_set
        mov     eax, GUEST_RESET
        mov     [rbx + CPU_PC], rax
        mov     [rbx + CPU_ENTRY], rax
        mov     [rbx + CPU_FETCH_PC], rax
        xor     eax, eax
        mov     [rbx + CPU_MCYCLE], rax
        mov     [rbx + CPU_MINSTRET], rax
        mov     dword [rbx + CPU_HALT], 0
        mov     dword [rbx + CPU_HALT_CODE], 0
        mov     dword [rbx + CPU_PRIV], PRIV_M
        mov     dword [rbx + CPU_TRAP_PEND], 0
        mov     dword [rbx + CPU_SQUASH], 0
        mov     dword [rbx + CPU_TRACE_LEN], 0
        mov     qword [rbx + CPU_MSTATUS], MSTATUS_MPP_M
        mov     qword [rbx + CPU_MIE], 0
        mov     qword [rbx + CPU_MTVEC], 0
        mov     qword [rbx + CPU_MSCRATCH], 0
        mov     qword [rbx + CPU_MEPC], 0
        mov     qword [rbx + CPU_MCAUSE], 0
        mov     qword [rbx + CPU_MTVAL], 0
        mov     qword [rbx + CPU_MIP], 0
        ; stack top
        mov     rax, [rbx + CPU_MEM_SIZE]
        add     rax, GUEST_RESET
        sub     rax, 16
        mov     [rbx + CPU_STACK_TOP], rax
        mov     [rbx + CPU_X + 2*8], rax        ; x2 = sp
        mov     eax, GUEST_HEAP_BASE
        mov     [rbx + CPU_HEAP_BRK], rax
        ; default run caps: 50e6 inst, 200e6 cycles
        mov     rax, 50000000
        mov     [rbx + CPU_MAX_INST], rax
        mov     rax, 200000000
        mov     [rbx + CPU_MAX_CYCLE], rax
        pop     rbx
        ret

; uint32 cpu_get_x(cpu*, unsigned rd)
PROC cpu_get_x
        test    esi, esi
        jz      .zero
        cmp     esi, 32
        jae     .zero
        mov     eax, esi
        mov     eax, [rdi + CPU_X + rax*8]
        ret
.zero:
        xor     eax, eax
        ret

; void cpu_set_x(cpu*, unsigned rd, uint32 val)
PROC cpu_set_x
        test    esi, esi
        jz      .skip
        cmp     esi, 32
        jae     .skip
        mov     eax, esi
        mov     ecx, edx
        mov     dword [rdi + CPU_X + rax*8], ecx
        mov     dword [rdi + CPU_X + rax*8 + 4], 0
.skip:
        ret

; void cpu_set_pc(cpu*, uint32 pc)
PROC cpu_set_pc
        mov     eax, esi
        mov     [rdi + CPU_PC], rax
        ret

; uint32 cpu_get_pc(cpu*)
PROC cpu_get_pc
        mov     eax, [rdi + CPU_PC]
        ret

; void cpu_halt(cpu*, int reason, int code)
PROC cpu_halt
        mov     [rdi + CPU_HALT], esi
        mov     [rdi + CPU_HALT_CODE], edx
        ret

; void cpu_trace_push(cpu*, uint32 pc, uint32 inst)
PROC cpu_trace_push
        push    rbx
        mov     r8, [rdi + CPU_TRACE]
        test    r8, r8
        jz      .done
        mov     ebx, edx                ; inst
        mov     eax, [rdi + CPU_TRACE_LEN]
        mov     ecx, [rdi + CPU_TRACE_CAP]
        test    ecx, ecx
        jz      .done
        xor     edx, edx
        div     ecx                     ; edx = slot
        mov     eax, edx
        imul    rax, TRACE_ENT_SIZE
        add     r8, rax
        mov     [r8 + TRACE_ENT_PC], esi
        mov     [r8 + TRACE_ENT_INST], ebx
        inc     dword [rdi + CPU_TRACE_LEN]
.done:
        pop     rbx
        ret
