# Virtual memory

## What is it

Memory management technique, to make it look like we have more RAM than it physically has.

It works by moving some of the physical RAM to SSD when running low on space.


## Memory paging

## Swap Space

## Page faults


## Tradeoffs

Thrashing: RAM is thousands of times faster than a hard drive or SSD. So massive speed penalty. If system runs out of RAM completely and is forced to constantly swap data from drive to RAM, the computer will grind to a halt, which is known as thrashing.

If your system runs out of physical RAM completely and is constantly forced to swap data back and forth between the drive and RAM, your computer will grind to a halt. This state of sluggishness is known as thrashing.