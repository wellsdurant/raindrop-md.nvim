#!/usr/bin/env -S nvim -l

-- Simple Benchmark Example
-- This is a minimal example showing how to benchmark specific operations
-- Run with: nvim --headless +"luafile benchmark/simple_example.lua" +qa
-- Or from within Neovim: :luafile benchmark/simple_example.lua

-- Setup
vim.opt.runtimepath:append(".")

-- Check for required dependencies
local function check_dependency(name)
  local ok, _ = pcall(require, name)
  return ok
end

if not check_dependency("plenary.curl") then
  print("\nError: plenary.nvim is required but not found!")
  print("\nPlease run this example using one of these methods:\n")
  print("1. From within Neovim (with your config loaded):")
  print("   :luafile benchmark/simple_example.lua\n")
  print("2. With headless Neovim (loads your config):")
  print("   nvim --headless +'luafile benchmark/simple_example.lua' +qa\n")
  os.exit(1)
end

vim.cmd("runtime! plugin/**/*.lua")

local benchmark = require("raindrop-md.benchmark")
local cache = require("raindrop-md.cache")
local config = require("raindrop-md.config")

-- Configure plugin
config.setup({
  cache_file = vim.fn.stdpath("cache") .. "/raindrop-md/bookmarks.json",
})

print("\n=== Simple Benchmark Example ===\n")

-- Example 1: Time a synchronous operation
print("1. Synchronous operation:")
local bookmarks = benchmark.time_sync("Read cache", function()
  return cache.read()
end)

if bookmarks then
  print("   Found " .. #bookmarks .. " cached bookmarks\n")
else
  print("   No cache available\n")
end

-- Example 2: Time an async operation
print("2. Asynchronous operation:")
local done = false
local result = nil

benchmark.time_async("Get bookmarks", function(callback)
  cache.get_bookmarks(false, function(data)
    result = data
    callback(data)
  end)
end, function(data)
  done = true
end)

-- Wait for async operation
while not done do
  vim.loop.run("nowait")
end

if result then
  print("   Retrieved " .. #result .. " bookmarks\n")
end

-- Example 3: Run multiple iterations
print("3. Statistical analysis (10 iterations):")
if bookmarks and #bookmarks > 0 then
  benchmark.time_iterations("JSON encode", function()
    vim.json.encode(bookmarks)
  end, 10)
else
  print("   Skipped (no data)\n")
end

-- Example 4: Memory profiling
print("\n4. Memory measurement:")
if bookmarks and #bookmarks > 0 then
  -- Direct size measurement (more accurate)
  benchmark.measure_size("Bookmarks cache", bookmarks)

  -- GC-based profiling (can be negative due to garbage collection)
  print("")
  benchmark.profile_memory("JSON operations", function()
    local json = vim.json.encode(bookmarks)
    local decoded = vim.json.decode(json)
  end)
else
  print("   Skipped (no data)\n")
end

-- Example 5: Manual timer
print("\n5. Manual timer control:")
local stop = benchmark.start_timer("Custom workflow")

-- Simulate some work
if bookmarks then
  -- Sort bookmarks
  local sorted = vim.deepcopy(bookmarks)
  table.sort(sorted, function(a, b)
    return (a.title or "") < (b.title or "")
  end)

  -- Process titles
  for _, bm in ipairs(sorted) do
    local _ = (bm.title or ""):upper()
  end
end

stop()

print("\n=== Benchmark Complete ===\n")

-- Exit
os.exit(0)
