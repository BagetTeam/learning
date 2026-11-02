```py
from functools import wraps

def repeat(times):
    def decorator(func):
        @wraps(func)        # Preserve add() properties, like __name__, __doc__, etc
        def wrapper(*args, **kwargs):
            result = None

            for _ in range(times):
                result = func(*args, **kwargs)

            return result

        return wrapper

    return decorator


@repeat(3)
def add(a, b):
    return a + b

# Same as repeat(3)(add)
```

```py
@dec_a
@dec_b
def add():
    ...

# dec_a(dec_b(add))
```

pass in decorator, not calling it. Like a = add instead of a = add()
