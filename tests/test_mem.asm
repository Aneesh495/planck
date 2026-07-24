; tests/test_mem.asm
        bits 64
        default rel
%include "macros.inc"
%include "cpu.inc"
%include "rv32.inc"
%include "abi.inc"
        extern cpu_create
        extern cpu_reset
        extern cpu_set_x
        extern cpu_get_x
        extern guest_store_u32
        extern guest_load_u32
        extern pack_i
        extern pack_s
        extern interp_step

        section .bss
hart:    resq 1
tmp:    resd 1

        section .text
PROC test_mem
        push    rbx
        push    r12
        mov     rdi, DEFAULT_MEM_SIZE
        xor     esi, esi
        call    cpu_create
        mov     [rel hart], rax
        ; sw x1, 16(x2)  then lw x3, 16(x2)
        ; x1=0xA1B2C3D4 x2=0x80001000
        mov     rdi, [rel hart]
        call    cpu_reset
        mov     rdi, [rel hart]
        mov     esi, 1
        mov     edx, 0xA1B2C3D4
        call    cpu_set_x
        mov     rdi, [rel hart]
        mov     esi, 2
        mov     edx, 0x80001000
        call    cpu_set_x
        ; sw rs2=x1, rs1=x2, imm=16
        mov     edi, 2                  ; rs1
        mov     esi, 1                  ; rs2
        mov     edx, 16
        xor     ecx, ecx
        mov     ecx, F3_SW
        mov     r8d, OPC_STORE
        call    pack_s
        mov     rdi, [rel hart]
        mov     esi, GUEST_RESET
        mov     edx, eax
        call    guest_store_u32
        mov     rdi, [rel hart]
        call    interp_step
        ; check memory
        mov     rdi, [rel hart]
        mov     esi, 0x80001010
        lea     rdx, [rel tmp]
        call    guest_load_u32
        cmp     dword [rel tmp], 0xA1B2C3D4
        jne     .fail
        ; lw x3, 16(x2)
        mov     rdi, [rel hart]
        call    cpu_reset
        mov     rdi, [rel hart]
        mov     esi, 2
        mov     edx, 0x80001000
        call    cpu_set_x
        ; store the data first
        mov     rdi, [rel hart]
        mov     esi, 0x80001010
        mov     edx, 0xA1B2C3D4
        call    guest_store_u32
        mov     edi, 3
        mov     esi, 2
        mov     edx, 16
        mov     ecx, F3_LW
        mov     r8d, OPC_LOAD
        call    pack_i
        mov     rdi, [rel hart]
        mov     esi, GUEST_RESET
        mov     edx, eax
        call    guest_store_u32
        mov     rdi, [rel hart]
        call    interp_step
        mov     rdi, [rel hart]
        mov     esi, 3
        call    cpu_get_x
        cmp     eax, 0xA1B2C3D4
        jne     .fail
        ; store/load at the reset stack pointer (high end of guest RAM)
        mov     rdi, [rel hart]
        call    cpu_reset
        mov     rdi, [rel hart]
        mov     esi, 2
        call    cpu_get_x
        mov     r12d, eax               ; sp
        mov     rdi, [rel hart]
        mov     esi, r12d
        mov     edx, 0xAABBCCDD
        call    guest_store_u32
        test    eax, eax
        jnz     .fail
        mov     rdi, [rel hart]
        mov     esi, r12d
        lea     rdx, [rel tmp]
        call    guest_load_u32
        test    eax, eax
        jnz     .fail
        cmp     dword [rel tmp], 0xAABBCCDD
        jne     .fail
        xor     eax, eax
        pop     r12
        pop     rbx
        ret
.fail:
        mov     eax, 1
        pop     r12
        pop     rbx
        ret
