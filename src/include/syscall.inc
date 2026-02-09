%ifndef PLANCK_SYSCALL_INC
%define PLANCK_SYSCALL_INC

; Linux x86-64 syscall numbers used by the host. Nothing else.

SYS_READ            equ 0
SYS_WRITE           equ 1
SYS_CLOSE           equ 3
SYS_LSEEK           equ 8
SYS_MMAP            equ 9
SYS_MUNMAP          equ 11
SYS_EXIT            equ 60
SYS_CLOCK_GETTIME   equ 228
SYS_OPENAT          equ 257

AT_FDCWD            equ -100
O_RDONLY            equ 0
O_WRONLY            equ 1
O_RDWR              equ 2
O_CREAT             equ 64
O_TRUNC             equ 512
O_CLOEXEC           equ 524288

PROT_READ           equ 1
PROT_WRITE          equ 2
PROT_EXEC           equ 4

MAP_PRIVATE         equ 2
MAP_ANONYMOUS       equ 32

SEEK_SET            equ 0
SEEK_CUR            equ 1
SEEK_END            equ 2

CLOCK_MONOTONIC     equ 1

STDIN_FILENO        equ 0
STDOUT_FILENO       equ 1
STDERR_FILENO       equ 2

; mmap: rdi addr, rsi len, rdx prot, r10 flags, r8 fd, r9 off  (r10 not rcx)

EPERM               equ 1
ENOENT              equ 2
EIO                 equ 5
EBADF               equ 9
ENOMEM              equ 12
EACCES              equ 13
EFAULT              equ 14
EINVAL              equ 22
ENFILE              equ 23
EMFILE              equ 24
EROFS               equ 30

%endif
