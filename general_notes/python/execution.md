# Executing a .py file

While python is known as an interpreted language, it actually is both compiled and interpreted.

From Python source code -> machine code, it has 5 steps.

1. Source code
2. Lexing & Parser (AST)
3. Bytecode compilation
4. Bytecode
5. Python Virtual Machine
   1. Standard Library & built-ins
6. Operating System

## Lexing & Parsing (Source -> AST)

### Lexing (Tokenizer)

Transforms the source code to tokens based on keywords like `def`, `if`, operators, literals, etc. 

ex. `x = 5 + 3`
Breaking it into tokens:
- `x` -> NAME (identifier/var name)
- `=` -> ASSIGN (assignment operator)
- `5` -> NUMBER (int literal)
- `+` -> PLUS (arithmetic operations)
- `3` -> NUMBER (int literal)


### Parser

Takes tokens and builds a hierarchical tree structure, known as AST (Abstract Syntax Tree). Represents the logical structure and grammar of the program.

ex. `x = 5 + 3`
```
ASSIGN (node)
├── Target: Name (id='x')
└── Value: BinOp (Binary Operation: '+')
      ├── Left: Constant (value=5)
      └── Right: Constant (value=3)
```

*Note: There are built-in tools to see that tree if you want to write code to analyze code*


## Bytecode Compilation

Compiler turns AST to bytecode, a low-level platform-independent set of instructions (not machine code, CPU cannot execute it).

Python saves this bytecode into \_\_pycache\_\_ folder as a .pyc file. Cache hits if nothing is changed in file (skips lexing, parsing and compilation)

It looks like assembly code almost (low level)
ex. `x = 5 + 3`
```
1       0 LOAD_CONST           1 (5)
        2 LOAD_CONST           2 (3)
        4 BINARY_ADD
        6 STORE_NAME           0 (x)
        8 LOAD_CONST           3 (None)
        10 RETURN_VALUE
```

- LOAD_CONST: Puts the number 5, then 3 onto Python's evaluation stack.
- BINARY_ADD: Pops both numbers off the stack, adds them together (5 + 3), and pushes the result (8) back onto the stack.
- STORE_NAME: Takes that result (8) from the stack and binds it to the variable name x.

## Python Virtual Machine (PVM)

### Standard

Huge while loop, in C (since CPython is in C), which is interpreter.
Iteratates through bytecode instructions one by one and translate it to C instructions, interacting with operating system and RAM and execute them.

This loop is already compiled to machine code, so is like an executable which we pass the bytecode to.

Does not compile or translate the bytecode. Its interpreted!

### JIT Compilers (ex. PyPy)

Translates bytecode to machine code (Just-In-Time (JIT) compilation).
PyPy watches which bytecode instructions run frequently and compiles them straight into native CPU machine code on the fly to make things run much faster.

ex. 
```py
for i in range(1000000):
    x = i * 2
```

Instead of interpreting `x = i * 2` 1000000 times, as we are running the code, it detects what part of the code is most frequently executed (ex. its been 1000 times we run the same thing), decides to pause, then translates it to CPU machine code. Then it runs directly onto CPU instead of PVM loop, which is so much faster.
