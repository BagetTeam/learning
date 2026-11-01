# GIL (Global Interpreter Lock)

## What is it

Mechanism from Python's standard implementation, CPython, to prevent multiple threads to execute python bytecode in same interpreter.

Note: Python can run multiple threads, just GIL limits how many of them can run python code at the same time. Traditional GIL -> 1 thread, everything ran sequentially. 

## Why

Thread safety and memory management

CPython uses a technique called *reference counting* to manage memory

ex.
```py
data = [1, 2, 3]

a = data
b = data
```
Both a and b reference the same list. In CPython, it maintains a reference count of how many references exists of that object. When count goes to 0, object is removed immediately.
What does multithreading have anything to do with it.
1. If thread A reads reference count = 2
2. And thread B read reference count = 2
3. Thread A increments it to 3
4. Thread B increments it to what it read before, so 3
-> Should be 4

However, GIL does not guarantee thread safety, only for CPU-bound tasks.

CPU-bound:
- Loops with million of calculation
- process large dataset with pure python
- perform math algo with pure python
Since GIL blocks simultaneous Python bytecode to be executed, GIL makes it safe, but speed doesn't increase

I/O bound (wait for external thing):
- HTTP request
- Query database
- Read/Write file
- Waiting for network response

When it's waiting and not executing python code, GIL can be released, and allow another thread to execute

So threads share same GIL. 
Processes don't. So true parallelism is achieved with multiprocessing instead of multithreading.
-> Create process workers, each with their own python runtime


Note: In python 3.13, cpython supports free-threading build where GIL is disabled. Can check if GIL is active with `print(sys._is_gil_enabled())`


## Race Conditions

See this python code:
```py
counter = 0

def increment():
    global counter
    for _ in range(100_000):
        counter += 1

t1 = threading.Thread(target=increment)
t2 = threading.Thread(target=increment)
t1.start()
t2.start()
t1.join()
t2.join()

print(counter)
```


This could happen:
Steps | Thread 1 | Thread 2
1 | Read 5 | --
2 | Interrupted | Read 5
3 | -- | Write 6
4 | Write 6 | --

Reading and writing is not atomic, GIL allows them to take turns, just not ran at the same time. However, if no lock, even concurrent tasks can cause race conditions.

Fix:
```py
lock = threading.Lock()

def increment():
    global counter
    for _ in range(100_000):
        with lock:
            counter += 1
```


GIL is for object reference count, if not properly managed, interpreter could corrupt its memory management state.
But it doesn't look at internal operations. It doesn't know that
```py
if account.balance >= 100:
    account.balance -= 100
```
need to be executed together.

## Conclusion

GIL protects interpreter from internal concurrency problems. We manage our program logic when dealing with threads.