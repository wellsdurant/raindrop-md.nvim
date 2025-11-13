# Benchmark Quick Start

Get started with benchmarking in 2 minutes.

## Step 1: Generate Test Data

```bash
# Generate 100 sample bookmarks
nvim -l benchmark/generate_sample_cache.lua
```

Output:
```
✓ Generated 100 bookmarks
✓ Written to: ~/.cache/nvim/raindrop-md/bookmarks.json
✓ File size: 47 KB
```

## Step 2: Run Benchmarks

### Option A: Quick Benchmark (Fastest)

From Neovim:
```vim
:RaindropBenchmark
```

Output:
```
=== Quick Benchmark ===

[BENCH] Cache read: 0.31 ms
Cached bookmarks: 100

[BENCH] JSON encode: 0.07 ms

[MEMORY] Cache memory: 18.05 KB

===================
```

### Option B: Full Benchmark Suite

From Neovim:
```vim
:RaindropBenchmarkFull
```

Or from terminal:
```bash
nvim --headless +"luafile benchmark/run_benchmarks.lua" +qa
```

Output:
```
============================================================
  Raindrop-md.nvim Performance Benchmark Suite
============================================================

[1] Cache Operations
[BENCH] Check cache validity: 0.02 ms
[BENCH] Read cache (sync): 0.31 ms
  Cache contains 100 bookmarks
[MEMORY] Cache memory footprint: 18.05 KB

[2] API Operations
  No API token configured, skipping API benchmarks

[3] Data Processing Operations
[BENCH] JSON encode 100 bookmarks: 0.07 ms
[BENCH] JSON decode 100 bookmarks: 0.15 ms
[BENCH] Sort bookmarks by date: 0.04 ms
[BENCH] Clean excerpts: 0.03 ms

============================================================
  Benchmark Complete!
============================================================
```

## Step 3: Test Different Sizes

```bash
# Small dataset (fast)
nvim -l benchmark/generate_sample_cache.lua 50

# Medium dataset
nvim -l benchmark/generate_sample_cache.lua 250

# Large dataset (stress test)
nvim -l benchmark/generate_sample_cache.lua 1000

# Very large dataset
nvim -l benchmark/generate_sample_cache.lua 5000
```

Then run benchmarks again to see performance differences.

## Step 4: Use in Your Code

```lua
local benchmark = require("raindrop-md.benchmark")

-- Time any operation
benchmark.time_sync("My operation", function()
  -- your code
  return result
end)

-- Output: [BENCH] My operation: 1.23 ms
```

## Common Benchmark Scenarios

### Compare Cache Performance

```bash
# Generate different sizes and benchmark each
for size in 100 500 1000 2500 5000; do
  echo "Testing with $size bookmarks..."
  nvim -l benchmark/generate_sample_cache.lua $size
  nvim --headless +"luafile benchmark/simple_example.lua" +qa
done
```

### Test Memory Usage

Generate increasingly large datasets and monitor memory:

```bash
nvim -l benchmark/generate_sample_cache.lua 10000
nvim --headless +"luafile benchmark/simple_example.lua" +qa | grep MEMORY
```

### Profile Specific Operations

```lua
-- In your Neovim config or test file
local benchmark = require("raindrop-md.benchmark")

-- Test cache read speed
benchmark.time_sync("Cache read", function()
  return require("raindrop-md.cache").read()
end)

-- Test with iterations for statistical accuracy
benchmark.time_iterations("Cache read", function()
  require("raindrop-md.cache").read()
end, 50)
```

## Understanding Results

### Memory Measurements

**[SIZE]** - Direct measurement (accurate)
```
[SIZE] Bookmarks cache: 240.38 KB (246149 bytes)
```
This shows the actual size of your data.

**[MEMORY]** - GC-based (can be negative)
```
[MEMORY] JSON operations: -48.00 KB
```
Negative values mean Lua's garbage collector cleaned up more memory than was allocated. This is normal! Use **[SIZE]** for accurate measurements.

### Good Performance Indicators

- **Cache read**: < 1ms for 100 bookmarks, < 5ms for 1000
- **JSON encode**: < 0.5ms for 100 bookmarks
- **Memory**: < 100 KB per 1000 bookmarks (~100 bytes per bookmark)

### Performance Degrades?

If you see slow performance:

1. Check file size: `ls -lh ~/.cache/nvim/raindrop-md/bookmarks.json`
2. Clear and regenerate: `:RaindropClearCache` then regenerate
3. Reduce dataset size for your use case
4. Enable `cache_expiration` in config

## Next Steps

- Read [BENCHMARKING.md](./BENCHMARKING.md) for detailed guide
- Try the [simple_example.lua](./simple_example.lua) to learn the API
- Run [run_benchmarks.lua](./run_benchmarks.lua) for comprehensive tests

---

**Tip**: Run benchmarks after plugin updates to ensure no performance regressions!
