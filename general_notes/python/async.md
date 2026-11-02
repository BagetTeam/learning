# Asynchronism

## Async

`async def fun()`
This defines a coroutine function.

doing `coroutine = hello()` does not execute the body. Instead you get a coroutine object. Which is executed by event loop

## Await

Await allows coroutine to suspend execution until an awaitable operation completes.

## Event Loop

Responsible for scheduling and managing async tasks. 
Tasks are only switch on await. 
-> However, blocked by CPU intensive tasks. (threads are for this)

## How to use

```py
# run sequencially
await task_a()
await task_b()

await asyncio.gather(task_a(), task_b()) # runs both tasks concurrently, however, task_b is only ran after the `await` of task_a 
```

Basically, event loop is like an infinite loop, where when we `await`, it suspends and gives control to event loop

```py
while True:
    task = get_next_ready_task()
    task.resume()
```

A bypass, is during the CPU intensive task, you do `await asyncio.sleep(0)`. Let other run and continue.


## How does it know when await is done

Event loop doesn't constantly check every suspended tasks. Instead, relies on mechanisms such as OS notifications, timers, and callbacks.

How it works:
1. Call `await` -> coroutine suspends, preserve vars and execution position
2. `asyncio.Task` object maintains coroutine state
3. Tasks becomes a `Future`, representing task it is waiting for
4. Event loop runs other ready tasks
5. We receive `Future` completion callback
6. Task is scheduled to ready **queue**, and waits its turn 
7. Continue task where it left off, but with result from the await
*Note: It is the task's continuation callback that is stored in queue (not task object iself)*