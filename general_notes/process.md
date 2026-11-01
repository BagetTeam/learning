# Process

## What is a process

A unit of execution, with independent memory space and system resources from other processes. It's an instance of a running program, managed by the kernel (OS).

If they are independent from each other, can 2 process talk to each other. 
Yes: however, they must use Inter-Process Communication (IPC).

The OS 


## Linux fork/exec

fork(): Create a new process, cloning the current process. Returns value of PID (new PID in parent process, 0 in child process, -1 = fail).

exec(): Replace clone's memory with entirely new program. Use execv(path, args), 

When running from terminal, it actually takes in not only arguments of program we run, but the program itself. Ex. ("./program arg1 arg2" -> ./program would be argument 0). This is because it actually does the fork() and exec() as such.

This creates a tree of processes from processes. With main process being the init, or modernly called systemd, (PID 1)

### How init is created

[ Power On ] 
     │
     ▼
[ Bootloader (GRUB/systemd-boot) ] 
     │
     ▼
[ OS Kernel ] (Initializes hardware and memory)
     │
     ▼
[ Kernel spawns PID 1: init ] ◄── The user-space starts here!
     │
     ├───► Spawns Login Screen (GDM/LightDM)
     ├───► Spawns Network Manager
     └───► Spawns SSH Daemon / Background Services

init/systemd exists in /sbin/init, or /lib/systemd/systemd. (init is a legacy linux system, nowadays its only systemd)

### Systemd

Launches services in parallel, all logs can be found in journald.
Tracks processes through cgroups

cgroups (Control Groups): allows for limit/account/isolate resources usage (CPU, memory, disk I/O, network) for a process or group of processes.
-> Every service (containing one or many processes), will have their own distinct cgroup folder (under /sys/fs/cgroup/system.slice/). This way, we dont have to track each individual PID, which used to be stored in .pid files., rather manage things as groups. Easier to spot and cleanup "zombie" processes.
(service is a background process or group of processes managed by the system)

Ex. Docker containers (Docker is a service, containers are child processes of that service)
-> Process container is like a room, and cgroups acts as the utility meter and regulator of that room, ensuring proper management of resources so they dont use too much.
-> All containers will be within the Docker cgroup.



# Thread

## What is a thread, vs process

A thread is some unit of execution also, but within a process. So all threads within some process will have shared memory space (heap, global variables, etc.), but with isolated stack. 
Because of this sharing, not properly handling synchronization (ex. mutex) from the multiple threads can cause a race conditions.

What about concurrent tasks, can this cause race conditions.
Yes: 


