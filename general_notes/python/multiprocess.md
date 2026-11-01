# Sharing Variables

## Problem

For true parallelism, we need multi processing, not threading. Since they have their own memory space, global variables are not shared anymore. So how can they access it from each other.

Answer: 

1. `multiprocessing.Value`: For simple numeric values.
Example code.
```py
def increment(counter, lock):
    for _ in range(100_000):
        with lock: # Cuz shared across process, counter needs lock
            counter.value += 1

counter = multiprocessing.Value('i', 0)
lock = multiprocessing.Lock()
processes = [
    multiprocessing.Process(
        target=increment,
        args=(counter, lock)
    )
    for _ in range(4)
] # 4 processes

for p in processes:
    p.start()

for p in processes:
    p.join()

print(counter.value)
```

2. Multiprocessing manager.
``` py
from multiprocessing import Process, Manager

def worker(shared_dict, index):
    shared_dict[index] = index * 10

with Manager() as manager:
    shared_dict = manager.dict()

    processes = [
        Process(target=worker, args=(shared_dict, i))
        for i in range(4)
    ]

    for p in processes:
        p.start()

    for p in processes:
        p.join()

    print(dict(shared_dict))

# {0: 0, 1: 10, 2: 20, 3: 30}
```