## Syscalls

### What

System call (syscall) is a programmatic way for user-space applications to requests services or resources from the kernel 
-> These include hardware, alter page tables, access memory from other processes

Program ran in unpriviledged user mode (Ring 3) cannot access these.
But kernel runs in priviledged kernel mode (Ring 0).

Syscall is a safe gateway between both. 
Example of syscalls:
- **File & I/O Management:** open(), read(), write(), close()
- **Process Control:** fork(), exec(), exit()
- **Memory Management:** mmap(), brk()
- **Interprocess Communication (IPC):** pipe(), socket()

### How it works

