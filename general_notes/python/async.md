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
-> Blocked by CPU intensive tasks.