# coil
A tiny cooperative threading module for Lua. Coil is based around coroutines,
allowing many cooperative threads to run simultaneously.

## Usage
The [coil.lua](coil.lua) file should be dropped into an existing project and
required by it.
```lua
coil = require "coil"
```
At the start of each frame `coil.update()` should be called and given the delta
time since the last call as its argument.
```lua
coil.update(deltatime)
```
Coil refers to each cooperative thread as a *task*; new tasks can be created by
using the `coil.add()` function.
```lua
-- prints the word "hello" each second for 5 seconds
coil.add(function()
  for i = 1, 5 do
    print("hello")
    coil.wait(1)
  end
end)
```

### coil.wait()
As tasks are cooperative, they must be manually yielded to allow other parts of
the program to continue. This is done by calling the `coil.wait()` function.
The function can be used to wait for different events before continuing.

* If wait is called with a number as its argument then it waits for that number
  of seconds before resuming.
* If wait is called with a callback created by coil.callback() it will wait
  until that callback function is called before resuming; it will return the
  arguments passed to the callback when it was called.
* If wait is called with no arguments it waits until the next frame
  (`coil.update()` call) before resuming; it returns the time that has passed
  since the last frame.

### coil.callback()
The `coil.callback()` function can be used to create a special callback which,
if passed to the `coil.wait()` function, will cause the task to wait until the
callback is called.
```lua
-- Prints "Hello world" when `cb()` is called.
coil.add(function()
  cb = coil.callback()
  coil.wait(cb)
  print("Hello world")
end)
```

### coil.update(dt)
This should be called at the start of each frame. Updates all the tasks,
running those which aren't waiting or paused. `dt` should be the amount of time
in seconds which has passed since the function was last called.

### coil.add(fn)
Adds a new task, the task will begin running on the next call to
`coil.update()`.
```lua
-- prints "hello world" every 2 seconds
coil.add(function()
  while 1 do
    print("hello world")
    coil.wait(2)
  end
end)
```

## Stopping a task
A task can be stopped and removed at any point by calling its `:stop()` method.
To do this the task must be assigned to a variable when it is created.
```lua
-- Adds a new task
local t = coil.add(function()
  coil.wait(1)
  print("hello")
end)

-- Removes the task before it has a chance to run
t:stop()
```

## Groups
Coil provides the ability to create task groups; these are objects which can
have tasks added to them, and which are in charge of updating and handling
their contained tasks. A group is created by calling the `coil.group()`
function.
```lua
local group = coil.group()
```

Once a group is created it acts independently of the `coil` object, and must
be updated each frame using its own update method.
```lua
group:update(deltatime)
```

To add a task to a group, the group's `add()` method should be used.
```lua
group:add(function()
  coil.wait(10)
  print("10 seconds have passed")
end)
```

A good example of where groups are useful is for games where you may have a set
of tasks which effect objects in the game world and which you want to pause
when the game is paused.  A group's tasks can be paused by simply neglecting
to call its `update()` method; when a group is destroyed its tasks are also
destroyed.


## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.

