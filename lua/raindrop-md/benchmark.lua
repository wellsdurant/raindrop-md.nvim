local M = {}

--- Benchmark a synchronous function
--- @param name string Name of the operation
--- @param fn function Function to benchmark
--- @return any Result of the function
function M.time_sync(name, fn)
  local start = vim.loop.hrtime()
  local result = fn()
  local elapsed = (vim.loop.hrtime() - start) / 1000000 -- Convert to ms
  print(string.format("[BENCH] %s: %.2f ms", name, elapsed))
  return result
end

--- Benchmark an async function with callback
--- @param name string Name of the operation
--- @param fn function Function that takes a callback as last parameter
--- @param callback function Callback to handle the result
function M.time_async(name, fn, callback)
  local start = vim.loop.hrtime()
  fn(function(result)
    local elapsed = (vim.loop.hrtime() - start) / 1000000
    print(string.format("[BENCH] %s: %.2f ms", name, elapsed))
    if callback then
      callback(result)
    end
  end)
end

--- Run multiple iterations and report statistics
--- @param name string Name of the operation
--- @param fn function Function to benchmark
--- @param iterations number Number of times to run
function M.time_iterations(name, fn, iterations)
  iterations = iterations or 10
  local times = {}

  for i = 1, iterations do
    local start = vim.loop.hrtime()
    fn()
    local elapsed = (vim.loop.hrtime() - start) / 1000000
    table.insert(times, elapsed)
  end

  -- Calculate statistics
  local total = 0
  local min = times[1]
  local max = times[1]

  for _, time in ipairs(times) do
    total = total + time
    if time < min then min = time end
    if time > max then max = time end
  end

  local avg = total / iterations

  print(string.format("[BENCH] %s (%d iterations):", name, iterations))
  print(string.format("  Average: %.2f ms", avg))
  print(string.format("  Min: %.2f ms", min))
  print(string.format("  Max: %.2f ms", max))
  print(string.format("  Total: %.2f ms", total))

  return { avg = avg, min = min, max = max, total = total }
end

--- Start a timer and return a function to stop it
--- @param name string Name of the operation
--- @return function Function to call when operation is complete
function M.start_timer(name)
  local start = vim.loop.hrtime()
  return function()
    local elapsed = (vim.loop.hrtime() - start) / 1000000
    print(string.format("[BENCH] %s: %.2f ms", name, elapsed))
    return elapsed
  end
end

--- Profile memory usage
--- @param name string Name of the operation
--- @param fn function Function to profile
function M.profile_memory(name, fn)
  collectgarbage("collect")
  collectgarbage("collect") -- Collect twice to stabilize
  local before = collectgarbage("count")

  local result = fn()

  collectgarbage("collect")
  collectgarbage("collect") -- Collect twice to stabilize
  local after = collectgarbage("count")
  local used = after - before

  -- Note: negative values mean GC cleaned up more than was allocated
  local sign = used >= 0 and "+" or ""
  print(string.format("[MEMORY] %s: %s%.2f KB", name, sign, used))
  return used, result
end

--- Measure object size directly (more accurate than GC-based measurement)
--- @param name string Name of the object
--- @param obj any Object to measure
function M.measure_size(name, obj)
  local json_str = vim.json.encode(obj)
  local size_bytes = #json_str
  local size_kb = size_bytes / 1024

  print(string.format("[SIZE] %s: %.2f KB (%d bytes)", name, size_kb, size_bytes))
  return size_kb
end

return M
