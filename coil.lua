--
-- coil
--
-- Copyright (c) 2014 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local coil = { _version = "0.1.0" }
coil.__index = coil
coil.tasks = {}


local unpack = unpack or table.unpack

local _assert = function(cond, msg, lvl) 
  if cond then return cond, msg, lvl end
  error(msg, lvl + 1)
end

local callback_mt = { 
  __call = function(t, ...)
    t.args = {...}
    t.ready = true
  end}


local task = {} 
task.__index = task


function task.new(fn, parent)
  local self = setmetatable({}, task)
  self.routine = coroutine.wrap(fn)
  self.parent = parent
  self.pausecount = 0
  return self
end


function task:pause()
  self.pausecount = self.pausecount + 1
end


function task:resume()
  _assert(self.pausecount > 0, "unbalanced resume()", 2)
  self.pausecount = self.pausecount - 1
end


function task:stop()
  coil.remove(self.parent, self)
end



function coil:update(dt)
  if #self == 0 then return end
  coil.deltatime = dt
  for i = #self, 1, -1 do 
    local task = self[i]
    if task.wait then
      -- Handle wait
      if type(task.wait) == "number" then
        -- Handle numerical wait
        task.wait = task.wait - dt
        if task.wait <= 0 then
          task.waitrem = task.wait
          task.wait = nil
        end
      elseif type(task.wait) == "table" then
        -- Handle callback object
        if task.wait.ready then
          task.wait = nil
        end
      end
    end
    if not task.wait and task.pausecount == 0 then
      -- Run task
      coil.current = task
      if not task.routine() then
        coil.remove(self, i)
      end
    end
  end
  coil.current = nil
end


function coil:add(fn)
  local t = task.new(fn, self)
  table.insert(self, t)
  return t
end


function coil:remove(t)
  if type(t) == "number" then
    self[t] = self[#self]
    table.remove(self)
    return
  end
  for i, task in ipairs(self) do
    if task == t then
      return coil.remove(self, i)
    end
  end
end


function coil.wait(x, y)
  -- Discard first argument if its a coil group
  x = getmetatable(x) == coil and y or x
  local c = coil.current
  _assert(c, "wait() called from outside a coroutine", 2)
  if type(x) == "number" then
    -- Handle numerical wait
    c.wait = (c.waitrem or 0) + x
    if c.wait <= 0 then
      c.waitrem = c.wait
      return
    else
      c.waitrem = nil
    end
  else
    -- Handle next-frame / callback wait
    _assert(x == nil or getmetatable(x) == callback_mt,
            "wait() expected number, callback object or nothing as argument",
            2)
    c.waitrem = nil
    c.wait = x
  end
  coroutine.yield(true)
  -- Return args if wait was a callback object
  if type(x) == "table" then
    return unpack(x.args)
  end
  -- Return delta time if wait had no args
  if x == nil then
    return coil.deltatime
  end
end


function coil.callback()
  return setmetatable({ ready = false }, callback_mt)
end


function coil.group()
  return setmetatable({}, coil)
end



local bound = {
  update  = function(...) return coil.update(coil.tasks, ...) end,
  add     = function(...) return coil.add(coil.tasks, ...) end,
  remove  = function(...) return coil.remove(coil.tasks, ...) end,
}
setmetatable(bound, coil)

return bound
