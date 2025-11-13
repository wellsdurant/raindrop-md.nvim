# Benchmarking Guide

This guide explains how to measure and optimize the performance of raindrop-md.nvim.

## Quick Start

### Easiest: Use Built-in Commands

The plugin provides user commands for easy benchmarking:

```vim
" Quick benchmark (cache read/write, memory)
:RaindropBenchmark

" Full comprehensive benchmark suite
:RaindropBenchmarkFull
```

### Run Full Benchmark Suite

**From within Neovim**:
```vim
:luafile benchmark/run_benchmarks.lua
```

**Or with headless Neovim** (loads your full config):
```bash
nvim --headless +"luafile benchmark/run_benchmarks.lua" +qa
```

This will test:
- Cache read/write operations
- API request speeds
- Data processing performance
- Telescope integration
- Memory usage

**Note**: The benchmark requires **plenary.nvim** to be installed in your Neovim configuration.

### Generate Sample Data (Testing Without API)

If you don't have an API token or want to test offline:

```bash
# Generate 100 sample bookmarks
nvim -l benchmark/generate_sample_cache.lua

# Generate 500 bookmarks for stress testing
nvim -l benchmark/generate_sample_cache.lua 500

# Generate 1000 bookmarks
nvim -l benchmark/generate_sample_cache.lua 1000
```

This creates realistic test data without requiring network access.

### Run Custom Benchmarks

Create your own benchmark script:

```lua
local benchmark = require("raindrop-md.benchmark")

-- Time a synchronous operation
benchmark.time_sync("My operation", function()
  -- Your code here
  return result
end)

-- Time an async operation
benchmark.time_async("Async operation", function(callback)
  -- Async code that calls callback when done
  callback(result)
end)

-- Run multiple iterations for statistical analysis
benchmark.time_iterations("Repeated operation", function()
  -- Code to benchmark
end, 100) -- Run 100 times
```

## Benchmark Modules

### 1. Benchmark Utility (`lua/raindrop-md/benchmark.lua`)

Core benchmarking functions:

- `time_sync(name, fn)` - Time synchronous operations
- `time_async(name, fn, callback)` - Time async operations
- `time_iterations(name, fn, iterations)` - Run multiple times, get statistics
- `start_timer(name)` - Manual timer control
- `profile_memory(name, fn)` - Measure memory usage

### 2. Full Benchmark Suite (`benchmark/run_benchmarks.lua`)

Comprehensive test covering:

**Section 1: Cache Operations**
- Cache validity checks
- Sync/async cache reads
- Memory footprint analysis

**Section 2: API Operations**
- Metadata fetching
- Single page retrieval
- Full bookmark sync
- Cache writing

**Section 3: Data Processing**
- JSON encoding/decoding
- Bookmark sorting
- Text processing (excerpt cleaning)

**Section 4: Cache Strategies**
- Cache hits vs misses
- Incremental vs full refresh
- Background updates

**Section 5: Telescope Integration**
- Entry preparation
- Fuzzy matching performance

## Writing Benchmarks

### Basic Timing

```lua
local benchmark = require("raindrop-md.benchmark")

-- Simple timing
local result = benchmark.time_sync("Load cache", function()
  return require("raindrop-md.cache").read()
end)
```

### Async Operations

```lua
-- Async with callback
benchmark.time_async("Fetch bookmarks", function(done)
  require("raindrop-md.api").fetch_bookmarks(function(result)
    done(result)
  end)
end, function(result)
  print("Got " .. #result.bookmarks .. " bookmarks")
end)
```

### Statistical Analysis

```lua
-- Run 50 times and get statistics
local stats = benchmark.time_iterations("Sort bookmarks", function()
  table.sort(bookmarks, function(a, b)
    return a.title < b.title
  end)
end, 50)

-- stats contains: avg, min, max, total
print("Average: " .. stats.avg .. "ms")
```

### Manual Timing

```lua
local stop = benchmark.start_timer("Custom operation")

-- Do some work...
local data = fetch_data()

-- More work...
process_data(data)

-- Stop timer and print result
stop()
```

### Memory Profiling

**Direct size measurement (recommended):**
```lua
-- Measure actual object size
local kb = benchmark.measure_size("My data", my_table)
-- Output: [SIZE] My data: 123.45 KB (126412 bytes)
```

**GC-based profiling (can show negative values):**
```lua
local kb_used = benchmark.profile_memory("Parse JSON", function()
  local data = vim.json.decode(large_json_string)
end)
-- Output: [MEMORY] Parse JSON: +15.23 KB  (or -10.45 KB if GC cleaned up)
```

**Why negative memory?** The GC-based method can show negative values when Lua's garbage collector cleans up more memory than the operation allocated. This is normal! Use `measure_size()` for accurate object size measurements.

## Performance Tips

### Caching
- Enable `preload = true` to load bookmarks on startup
- Adjust `cache_expiration` based on your update frequency
- Use incremental updates for large collections

### API Efficiency
- Increase `pagination_size` for fewer API calls
- Use `auto_update_interval` to batch updates
- Monitor `metadata_check_interval` for background checks

### Processing
- Excerpt cleaning is pre-processed during cache write
- Bookmarks are pre-sorted in cache for faster reads
- Use async I/O to avoid blocking the editor

## Interpreting Results

### Good Performance Targets

- **Cache read**: < 50ms for 1000 bookmarks
- **Cache write**: < 100ms for 1000 bookmarks
- **API single page**: < 500ms
- **Telescope open**: < 100ms with cache hit
- **Memory**: < 1MB per 1000 bookmarks

### Common Bottlenecks

1. **Large JSON parsing** - Pre-process data when writing cache
2. **API pagination** - Increase page size or use incremental updates
3. **Telescope entries** - Limit displayed fields, use lazy loading
4. **Network latency** - Enable caching and background updates

## Continuous Benchmarking

### In Your Config

Add benchmarking to your plugin setup:

```lua
require("raindrop-md").setup({
  -- Enable verbose mode to see timing info
  verbose = true,

  -- Your other config...
})

-- Benchmark your setup
local benchmark = require("raindrop-md.benchmark")
benchmark.time_sync("Plugin setup", function()
  require("raindrop-md").setup(config)
end)
```

### CI/CD Integration

Run benchmarks in your CI pipeline:

```bash
#!/bin/bash
# benchmark.sh
nvim --headless +"luafile benchmark/run_benchmarks.lua" +qa
```

### Regression Testing

Compare results over time:

```lua
-- Save benchmark results
local results = {
  timestamp = os.time(),
  cache_read_ms = 45.2,
  api_fetch_ms = 823.1,
  -- ...
}

-- Write to file for tracking
local file = io.open("benchmark/results.json", "a")
file:write(vim.json.encode(results) .. "\n")
file:close()
```

## Troubleshooting

### Benchmark Timeouts

Increase timeout for slow operations:

```lua
-- Default is 30 seconds, increase for large datasets
run_async_benchmark(name, fn, 60000) -- 60 seconds
```

### Inconsistent Results

Use iterations for more stable measurements:

```lua
-- Single run can vary
benchmark.time_sync("Flaky operation", fn)  -- 45ms, then 89ms, then 52ms...

-- Multiple runs give better average
benchmark.time_iterations("Stable measurement", fn, 10)  -- avg: 61.3ms
```

### Missing Dependencies

Some benchmarks require:
- Telescope for picker tests
- API token for remote tests
- Existing cache for read tests

The benchmark suite will skip unavailable tests automatically.

## Examples

### Benchmark Plugin Startup

```lua
-- benchmark/startup.lua
local benchmark = require("raindrop-md.benchmark")

benchmark.time_sync("Full plugin initialization", function()
  require("raindrop-md").setup({
    token = "your_token",
    preload = true,
  })
end)
```

### Compare Strategies

```lua
-- Compare full vs incremental update
local cache = require("raindrop-md.cache")

benchmark.time_async("Full refresh", function(done)
  cache.get_bookmarks(true, done)
end)

benchmark.time_async("Incremental update", function(done)
  cache.get_bookmarks(false, done)
end)
```

### Profile Specific Function

```lua
-- Wrap any function temporarily
local original_fn = require("raindrop-md.api").fetch_bookmarks
require("raindrop-md.api").fetch_bookmarks = function(callback)
  benchmark.time_async("API fetch", original_fn, callback)
end
```

## Contributing

When submitting performance improvements:

1. Run benchmarks before and after changes
2. Include results in PR description
3. Test with both small and large datasets
4. Check memory usage for leaks
5. Verify async operations don't block

---

**Need help?** Open an issue with your benchmark results and system info.
