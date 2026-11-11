## Reference Counting

## Cyclic Garbage Collection

Secondary memory management system that looks for circular referencing of objects. Since count never reaches 0, object is never removed. This is why we need this.

ex. 
```py
class Node:
    def __init__(self):
        self.next = None

# 1. Create two objects
a = Node()
b = Node()

# 2. Link them to each other (Cycle Created!)
a.next = b
b.next = a

# 3. Delete the original pointers
del a
del b
```

`del a` does not clean up `a` since `b` still has a reference to it. And then doing `del b` is similar, since `a` still exists.

### How it works

First, it doesn't check any simple types (int, string, etc) since they don't hold references to other objects. instead, they only track **container objects** (ex. lists, dicts, custom classes, tuples).

1. **Copy reference count**: Gets these container objects, create a trial copy of their reference count (`gc_refs`)
2. Go through every container object, look at objects it points to. If this object is a container object, decrement reference count of trial copy by 1.
This removes all references within isolated groups, leaving external references intact.
3. Check remaining trial count. Deallocate objects with `gc_refs = 0` and reclaim memory. 


However, this is hella slow, no way we constantly run this. Instead, it uses a generational approach, based on 'most objects die young.', for optimization.

| Generation | Description | Inspection Frequency |
| :--- | :--- | :--- |
| **Generation 0** | Newly created objects. | Scanned very frequently. |
| **Generation 1** | Objects that survived a Gen 0 scan. | Scanned occasionally. |
| **Generation 2** | Long-lived objects (survived Gen 1). | Scanned rarely. |

### When does it run

It runs periodically, but not something like once every 5min. It runs based on an event-based loop based on application's object allocation activity.

`gc.get_threshold()` -> `(700, 10, 10)` (default)
