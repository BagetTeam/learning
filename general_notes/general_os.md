## Daemon

Computer program that runs as background process rather than being under direct control of user interactions.

*Note: these processes usually have a 'd' at the end in traditional Unix systems (ex. sshd, httpd)*

### Characteristics

- No GUI
- Starts during system boot process and continue until shutdown
- Idle most of the time, only active when triggered by specific event, network request, system activity or hardware condition
- Handle essential system utilities, services and infrastructure tasks (ex. managing network connections, scheduling tasks, printing, logging system errors)

### Common examples

- sshd: listens for and manages incoming ssh connections
- crond: automatically run scheduled tasks and background scripts at specific time
- syslogd: collects, routes, and stores system logs messages and errors
- ntpd: synchronize clock with internet time servers


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

