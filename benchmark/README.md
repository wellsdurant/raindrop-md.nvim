# Benchmarking

Performance testing tools for raindrop-md.nvim.

**New to benchmarking?** Start with [QUICKSTART.md](./QUICKSTART.md) for a 2-minute guide.

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

**Or headless** (loads your config):
```bash
nvim --headless +"luafile benchmark/run_benchmarks.lua" +qa
```

Tests all operations: cache, API, processing, memory usage.

### Run Simple Example

**From within Neovim**:
```vim
:luafile benchmark/simple_example.lua
```

**Or headless**:
```bash
nvim --headless +"luafile benchmark/simple_example.lua" +qa
```

Shows basic benchmarking usage with minimal code.

### Generate Sample Data (No API Required)

To test benchmarks without API access, generate sample cache data:

```bash
# Generate 100 sample bookmarks (default)
nvim -l benchmark/generate_sample_cache.lua

# Generate custom amount
nvim -l benchmark/generate_sample_cache.lua 500
```

This creates a realistic cache file at `~/.cache/nvim/raindrop-md/bookmarks.json`.

### Requirements

- Neovim with Lua support
- **plenary.nvim** installed (required dependency)
- Plugin installed or available in runtimepath
- (Optional) Sample cache data for testing without API

## Files

- **`QUICKSTART.md`** - 2-minute getting started guide (start here!)
- `run_benchmarks.lua` - Comprehensive test suite
- `simple_example.lua` - Basic example for learning
- `generate_sample_cache.lua` - Create test data without API
- `BENCHMARKING.md` - Complete guide with examples and tips
- `TROUBLESHOOTING.md` - Common issues and solutions
- `README.md` - This file

## Basic Usage

```lua
local benchmark = require("raindrop-md.benchmark")

-- Time any operation
benchmark.time_sync("Operation name", function()
  -- your code
end)

-- Async operations
benchmark.time_async("Async op", function(done)
  api.fetch(function(result)
    done(result)
  end)
end)

-- Multiple iterations for stats
benchmark.time_iterations("Repeated op", fn, 100)

-- Measure object size (accurate)
benchmark.measure_size("My data", table_or_data)

-- Profile memory changes (can be negative due to GC)
benchmark.profile_memory("Operation", function()
  -- code that may allocate/free memory
end)
```

## What Gets Tested

1. **Cache Operations** - Read/write speed, memory usage
2. **API Calls** - Request latency, pagination efficiency
3. **Data Processing** - JSON parsing, sorting, text cleaning
4. **Cache Strategies** - Full vs incremental updates
5. **Telescope** - Entry preparation and display

## Requirements

- Neovim with Lua support
- Plugin installed in runtimepath
- (Optional) API token for remote tests
- (Optional) Telescope for picker tests

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.

## See Also

Read [BENCHMARKING.md](./BENCHMARKING.md) for:
- Detailed usage guide
- Performance optimization tips
- Writing custom benchmarks
- CI/CD integration
