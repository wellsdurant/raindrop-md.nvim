# Benchmark Troubleshooting

Common issues and solutions when running benchmarks.

## Issue: "plenary.curl not found"

### Symptoms

```
Error: module 'plenary.curl' not found
```

### Solution

Run benchmarks from within Neovim where plenary is loaded:

```vim
:luafile benchmark/run_benchmarks.lua
```

Or use headless mode with your config:
```bash
nvim --headless +"luafile benchmark/run_benchmarks.lua" +qa
```

## Issue: No Cache Data

### Symptoms

```
No cache file exists, skipping benchmark
```

### Solution

Generate sample cache data:

```bash
# Generate 100 bookmarks
nvim -l benchmark/generate_sample_cache.lua

# Or custom amount
nvim -l benchmark/generate_sample_cache.lua 500
```

## Issue: Benchmark Times Out

### Symptoms

```
TIMEOUT after 30000ms
```

### Cause

- Large dataset
- Slow network (for API tests)
- Slow disk I/O

### Solution

For large datasets, use the simple benchmark instead:

```bash
NO_COLOR=1 nvim --headless +"luafile benchmark/simple_example.lua" +qa
```

Or generate smaller test data:
```bash
nvim -l benchmark/generate_sample_cache.lua 50
```

## Issue: Negative Memory Values

### Symptoms

```
[MEMORY] JSON operations: -48.00 KB
```

### Cause

This is **normal**! Lua's garbage collector cleaned up more memory than the operation allocated.

### Solution

Use `[SIZE]` measurements for accurate values:

```
[SIZE] Bookmarks cache: 47.91 KB (49059 bytes)  ← Use this
[MEMORY] JSON operations: -48.00 KB             ← Can be negative
```

The `[MEMORY]` metric shows memory delta and can be negative. The `[SIZE]` metric measures actual object size.

## Issue: Permission Denied

### Symptoms

```
Error: Could not write to ~/.cache/nvim/raindrop-md/bookmarks.json
```

### Solution

Check directory permissions:

```bash
mkdir -p ~/.cache/nvim/raindrop-md
chmod 755 ~/.cache/nvim/raindrop-md
```

Or use a different cache location:

```lua
require("raindrop-md").setup({
  cache_file = "/tmp/raindrop-test/bookmarks.json"
})
```

## Need More Help?

1. Check the [BENCHMARKING.md](./BENCHMARKING.md) guide
2. Try the [QUICKSTART.md](./QUICKSTART.md) for a fresh start
3. Run the simple example: `:luafile benchmark/simple_example.lua`
4. Open an issue with your error output

---

**Quick Test**: Run this to verify everything works:

```bash
# 1. Generate test data
nvim -l benchmark/generate_sample_cache.lua 50

# 2. Run simple benchmark
nvim --headless +"luafile benchmark/simple_example.lua" +qa
```

If this works, your setup is correct!
