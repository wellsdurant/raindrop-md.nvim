#!/usr/bin/env -S nvim -l

-- Raindrop-md.nvim Benchmark Suite
-- Run with: nvim --headless +"luafile benchmark/run_benchmarks.lua" +qa
-- Or from within Neovim: :luafile benchmark/run_benchmarks.lua

-- Add plugin to runtime path
vim.opt.runtimepath:append(".")

-- Check for required dependencies
local function check_dependency(name)
  local ok, _ = pcall(require, name)
  return ok
end

if not check_dependency("plenary.curl") then
  print("\nError: plenary.nvim is required but not found!")
  print("\nPlease run benchmarks using one of these methods:\n")
  print("1. From within Neovim (with your config loaded):")
  print("   :luafile benchmark/run_benchmarks.lua\n")
  print("2. With headless Neovim (loads your config):")
  print("   nvim --headless +'luafile benchmark/run_benchmarks.lua' +qa\n")
  print("3. Install plenary.nvim in your Neovim config")
  os.exit(1)
end

-- Setup minimal environment
vim.cmd("runtime! plugin/**/*.vim")
vim.cmd("runtime! plugin/**/*.lua")

local benchmark = require("raindrop-md.benchmark")
local cache = require("raindrop-md.cache")
local api = require("raindrop-md.api")
local config = require("raindrop-md.config")

-- No colors by default (clean output everywhere)
local function green(text) return text end
local function yellow(text) return text end
local function blue(text) return text end
local function cyan(text) return text end
local function bold(text) return text end

-- Banner
print(bold("\n" .. string.rep("=", 60)))
print(bold("  Raindrop-md.nvim Performance Benchmark Suite"))
print(bold(string.rep("=", 60) .. "\n"))

-- Setup plugin with default config
config.setup({
  cache_file = vim.fn.stdpath("cache") .. "/raindrop-md/bookmarks.json",
  cache_expiration = 3600,
  verbose = false, -- Disable verbose mode for clean benchmark output
})

print(cyan("Configuration:"))
print("  Cache file: " .. config.get("cache_file"))
print("  Cache expiration: " .. config.get("cache_expiration") .. " seconds\n")

-- Track all benchmark results
local results = {}

-- Helper to run async benchmarks with timeout
local function run_async_benchmark(name, fn, timeout)
  timeout = timeout or 30000 -- 30 second default timeout
  local done = false
  local result = nil

  print(yellow("Running: ") .. name .. "...")
  local stop_timer = benchmark.start_timer(name)

  fn(function(data)
    done = true
    result = data
    stop_timer()
  end)

  -- Wait for completion with timeout
  local start_time = vim.loop.hrtime()
  while not done do
    vim.loop.run("nowait")
    local elapsed = (vim.loop.hrtime() - start_time) / 1000000
    if elapsed > timeout then
      print(color("31", "  TIMEOUT after " .. timeout .. "ms"))
      return nil
    end
  end

  return result
end

-- ============================================================================
-- SECTION 1: Cache Operations
-- ============================================================================

print(bold(blue("\n[1] Cache Operations\n")))

-- Benchmark 1.1: Check if cache exists
benchmark.time_sync("1.1 Check cache validity", function()
  return vim.loop.fs_stat(config.get("cache_file"))
end)

-- Benchmark 1.2: Read cache (if exists)
local cached_bookmarks = nil
local cache_size = 0

if vim.loop.fs_stat(config.get("cache_file")) then
  cached_bookmarks = benchmark.time_sync("1.2 Read cache (sync)", function()
    return cache.read()
  end)

  if cached_bookmarks then
    cache_size = #cached_bookmarks
    print(green("  Cache contains " .. cache_size .. " bookmarks"))
  end
else
  print(yellow("  No cache file exists, skipping read benchmark"))
end

-- Benchmark 1.3: Memory usage of cached bookmarks
if cached_bookmarks then
  benchmark.measure_size("1.3 Cache data size", cached_bookmarks)
end

-- ============================================================================
-- SECTION 2: API Operations
-- ============================================================================

print(bold(blue("\n[2] API Operations\n")))

-- Check if we have an API token
local token = config.get("token")
if not token or token == "" then
  print(yellow("  No API token configured, skipping API benchmarks"))
  print(yellow("  Set token in your config to test API operations\n"))
else
  -- Benchmark 2.1: Get bookmark metadata (lightweight check)
  run_async_benchmark("2.1 Fetch bookmark metadata", function(callback)
    api.get_bookmark_metadata(function(result)
      if not result.error then
        print(green("  Total bookmarks: " .. (result.count or 0)))
        if result.last_update then
          print(green("  Last updated: " .. result.last_update))
        end
      end
      callback(result)
    end)
  end, 10000)

  -- Benchmark 2.2: Fetch single page
  run_async_benchmark("2.2 Fetch single page (50 items)", function(callback)
    api.fetch_all_bookmarks_paginated(0, function(result)
      if not result.error then
        print(green("  Fetched " .. #result.bookmarks .. " bookmarks"))
      end
      callback(result)
    end)
  end, 10000)

  -- Benchmark 2.3: Full bookmark fetch (if reasonable size)
  local should_test_full_fetch = false
  api.get_bookmark_metadata(function(result)
    if not result.error and result.count and result.count < 500 then
      should_test_full_fetch = true
    end
  end)

  -- Wait for metadata check
  local wait_start = vim.loop.hrtime()
  while should_test_full_fetch == false do
    vim.loop.run("nowait")
    if (vim.loop.hrtime() - wait_start) / 1000000 > 5000 then
      break
    end
  end

  if should_test_full_fetch then
    local all_bookmarks = run_async_benchmark("2.3 Fetch all bookmarks", function(callback)
      api.fetch_bookmarks(function(result)
        if not result.error then
          print(green("  Fetched " .. #result.bookmarks .. " total bookmarks"))
        end
        callback(result.bookmarks)
      end)
    end, 60000)

    -- Benchmark 2.4: Write to cache
    if all_bookmarks and #all_bookmarks > 0 then
      benchmark.time_sync("2.4 Write bookmarks to cache", function()
        cache.write(all_bookmarks, #all_bookmarks)
      end)

      -- Let the async write complete
      for i = 1, 10 do
        vim.loop.run("nowait")
      end
    end
  else
    print(yellow("  Skipping full fetch benchmark (too many bookmarks or API error)"))
  end
end

-- ============================================================================
-- SECTION 3: Data Processing Operations
-- ============================================================================

print(bold(blue("\n[3] Data Processing Operations\n")))

if cached_bookmarks and #cached_bookmarks > 0 then
  -- Benchmark 3.1: JSON encoding
  benchmark.time_sync("3.1 JSON encode " .. #cached_bookmarks .. " bookmarks", function()
    return vim.json.encode(cached_bookmarks)
  end)

  -- Benchmark 3.2: JSON decoding
  local json_str = vim.json.encode(cached_bookmarks)
  benchmark.time_sync("3.2 JSON decode " .. #cached_bookmarks .. " bookmarks", function()
    return vim.json.decode(json_str)
  end)

  -- Benchmark 3.3: Bookmark sorting
  benchmark.time_sync("3.3 Sort bookmarks by date", function()
    local copy = vim.deepcopy(cached_bookmarks)
    table.sort(copy, function(a, b)
      local a_time = a.lastUpdate or a.created or ""
      local b_time = b.lastUpdate or b.created or ""
      return a_time > b_time
    end)
    return copy
  end)

  -- Benchmark 3.4: Excerpt cleaning (simulate processing)
  benchmark.time_sync("3.4 Clean excerpts", function()
    local count = 0
    for _, bookmark in ipairs(cached_bookmarks) do
      if bookmark.excerpt then
        local _ = bookmark.excerpt:gsub("[\r\n]+", " "):gsub("%s+", " ")
        count = count + 1
      end
    end
    return count
  end)
else
  print(yellow("  No cached bookmarks available for processing benchmarks"))
end

-- ============================================================================
-- SECTION 4: Cache Strategy Comparison
-- ============================================================================

print(bold(blue("\n[4] Cache Strategy Comparison\n")))

if cached_bookmarks and #cached_bookmarks > 0 then
  -- Benchmark 4.1: Get bookmarks (cache hit, no refresh)
  run_async_benchmark("4.1 Get bookmarks (cached)", function(callback)
    cache.get_bookmarks(false, callback)
  end, 5000)

  -- Benchmark 4.2: Get bookmarks (force refresh) - only if API available
  if token and token ~= "" then
    run_async_benchmark("4.2 Get bookmarks (force refresh)", function(callback)
      cache.get_bookmarks(true, callback)
    end, 60000)
  end
end

-- ============================================================================
-- SECTION 5: Telescope Integration (if available)
-- ============================================================================

print(bold(blue("\n[5] Telescope Integration\n")))

local has_telescope = pcall(require, "telescope")
if has_telescope and cached_bookmarks and #cached_bookmarks > 0 then
  local telescope_module = require("raindrop-md.telescope")

  -- Note: We can't actually open Telescope in headless mode,
  -- but we can benchmark the data preparation
  benchmark.time_sync("5.1 Prepare Telescope entries", function()
    -- Simulate entry preparation
    local entries = {}
    for _, bookmark in ipairs(cached_bookmarks) do
      table.insert(entries, {
        value = bookmark,
        display = bookmark.title,
        ordinal = bookmark.title .. " " .. (bookmark.domain or ""),
      })
    end
    return entries
  end)
else
  if not has_telescope then
    print(yellow("  Telescope not available, skipping"))
  elseif not cached_bookmarks then
    print(yellow("  No cached bookmarks, skipping"))
  end
end

-- ============================================================================
-- Summary
-- ============================================================================

print(bold(blue("\n" .. string.rep("=", 60))))
print(bold("  Benchmark Complete!"))
print(bold(string.rep("=", 60) .. "\n"))

print(green("Summary:"))
if cached_bookmarks then
  print("  Cached bookmarks: " .. #cached_bookmarks)
end
if token and token ~= "" then
  print("  API token: Configured")
else
  print("  API token: Not configured (some benchmarks skipped)")
end
print()

print(cyan("To run specific benchmarks:"))
print("  1. Make sure your API token is configured")
print("  2. Run: nvim -l benchmark/run_benchmarks.lua")
print("  3. Or integrate with your test suite\n")

-- Exit
os.exit(0)
