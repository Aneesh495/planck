; src/host/syscall.asm
; Thin Linux x86-64 syscall wrappers. mmap remaps rcx → r10 as the kernel wants.

        bits 64
        default rel

%include "macros.inc"
%include "syscall.inc"

        section .text

; ssize_t sys_read(int fd, void *buf, size_t n)
PROC sys_read
        mov     eax, SYS_READ
        syscall
        ret

; ssize_t sys_write(int fd, const void *buf, size_t n)
PROC sys_write
        mov     eax, SYS_WRITE
        syscall
        ret

; int sys_close(int fd)
PROC sys_close
        mov     eax, SYS_CLOSE
        syscall
        ret

; int sys_openat(int dirfd, const char *path, int flags, int mode)
; args already rdi,rsi,rdx,rcx — kernel wants r10 = mode? 
; openat(dirfd, path, flags, mode): rdi, rsi, rdx, r10
PROC sys_openat
        mov     r10, rcx
        mov     eax, SYS_OPENAT
        syscall
        ret

; off_t sys_lseek(int fd, off_t off, int whence)
PROC sys_lseek
        mov     eax, SYS_LSEEK
        syscall
        ret

; void *sys_mmap(void *addr, size_t len, int prot, int flags, int fd, off_t off)
; SysV: rdi rsi rdx rcx r8 r9  → kernel: rdi rsi rdx r10 r8 r9
PROC sys_mmap
        mov     r10, rcx
        mov     eax, SYS_MMAP
        syscall
        ret

; int sys_munmap(void *addr, size_t len)
PROC sys_munmap
        mov     eax, SYS_MUNMAP
        syscall
        ret

; void sys_exit(int code)  noreturn
PROC sys_exit
        mov     eax, SYS_EXIT
        syscall
        hlt

; int sys_clock_gettime(int clk, struct timespec *ts)
PROC sys_clock_gettime
        mov     eax, SYS_CLOCK_GETTIME
        syscall
        ret
