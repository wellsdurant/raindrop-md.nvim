-- User command wrapper for running benchmarks from within Neovim
-- Usage: :RaindropBenchmark

local M = {}

function M.run_full_benchmark()
  -- Run the full benchmark suite
  local benchmark_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/benchmark/run_benchmarks.lua"

  if vim.fn.filereadable(benchmark_file) == 0 then
    vim.notify("Benchmark file not found: " .. benchmark_file, vim.log.levels.ERROR)
    return
  end

  vim.cmd("luafile " .. benchmark_file)
end

function M.run_simple_benchmark()
  -- Run the simple example
  local benchmark_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/benchmark/simple_example.lua"

  if vim.fn.filereadable(benchmark_file) == 0 then
    vim.notify("Benchmark file not found: " .. benchmark_file, vim.log.levels.ERROR)
    return
  end

  vim.cmd("luafile " .. benchmark_file)
end

function M.quick_benchmark()
  -- Quick benchmark of current cache state
  local benchmark = require("raindrop-md.benchmark")
  local cache = require("raindrop-md.cache")

  print("\n=== Quick Benchmark ===\n")

  -- Test cache read
  local bookmarks = benchmark.time_sync("Cache read", function()
    return cache.read()
  end)

  if bookmarks then
    print("Cached bookmarks: " .. #bookmarks .. "\n")

    -- Test JSON encoding
    benchmark.time_sync("JSON encode", function()
      return vim.json.encode(bookmarks)
    end)

    -- Measure size directly
    print("")
    benchmark.measure_size("Cache data", bookmarks)
  else
    print("No cache available")
  end

  print("\n===================\n")
end

return M
