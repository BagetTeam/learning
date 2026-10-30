# Runtime
Software layer that executes, manages and supports an application while it is actively running on a computer system
- Python -> CPython
- Java -> JVM
- C# -> .NET

For C/C++, while it is compiled languages (unlike these interpreted languages), it still needs a runtime
Compiler works like this:
1. Preprocessor
2. Compiler
3. Assembler
4. Linker
5. We now have executable

In Linker, this is where we have a runtime also passed to it. Purpose of runtime:
- Startup routines:
- - Prepare env vars
- - Initialize standard I/O (stdin, stdout, stderr), memory allocation (malloc free)
- - Locate program arguments and prepare argc and argv[]
- - Calling main, and passing argc and argv.
- - Setting up thread-local storage and runtime state for initial thread
- - Initialize secrutiy mechanisms (stack cookies)
- - Prepare normal termination (set cleanup and flushes buffered output routines for when main function returns)


So actually main(argc, argv) is not first thing that is ran, there is all this starting code
