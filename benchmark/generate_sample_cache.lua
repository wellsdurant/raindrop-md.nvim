#!/usr/bin/env -S nvim -l

-- Generate Sample Cache for Benchmarking
-- Creates a realistic cache file without requiring API access
-- Run with: nvim -l benchmark/generate_sample_cache.lua [count]

-- Setup
vim.opt.runtimepath:append(".")

-- Parse command line arguments
-- vim.v.argv contains: [nvim, -l, script.lua, arg1, arg2, ...]
local bookmark_count = 100
for i, arg in ipairs(vim.v.argv) do
  if i > 3 and tonumber(arg) then
    bookmark_count = tonumber(arg)
    break
  end
end

print("\n=== Generating Sample Cache ===\n")
print("Creating " .. bookmark_count .. " sample bookmarks...")

-- Sample data for realistic bookmarks
local sample_titles = {
  "Neovim Documentation - Getting Started",
  "Lua Programming Language - Official Site",
  "GitHub - neovim/neovim: Vim-fork focused on extensibility",
  "Telescope.nvim - Fuzzy Finder Plugin",
  "Understanding Async Programming in Lua",
  "Best Practices for Neovim Plugin Development",
  "Plenary.nvim - Utility Library for Neovim",
  "LSP Configuration Guide for Neovim",
  "Treesitter Integration in Neovim",
  "Writing Efficient Lua Code",
  "Vim Motion Commands Reference",
  "Advanced Text Objects in Neovim",
  "Modern Development Workflow with Neovim",
  "Debugging Lua Scripts in Neovim",
  "Performance Optimization Tips for Plugins",
  "Markdown Preview in Neovim",
  "Git Integration with Neovim",
  "Terminal Management in Neovim",
  "Color Schemes and Theming Guide",
  "Keybinding Best Practices"
}

local sample_domains = {
  "neovim.io",
  "lua.org",
  "github.com",
  "stackoverflow.com",
  "dev.to",
  "medium.com",
  "reddit.com",
  "docs.python.org",
  "javascript.info",
  "rust-lang.org"
}

local sample_excerpts = {
  "A comprehensive guide to getting started with modern text editing. Learn the basics and advanced features.",
  "Official documentation covering installation, configuration, and usage. Includes API reference and examples.",
  "Step-by-step tutorial with practical examples and best practices for real-world applications.",
  "In-depth article exploring advanced techniques and performance optimization strategies.",
  "Community discussion about common problems and their solutions. Includes code snippets and tips.",
  "Technical deep-dive into implementation details and design patterns. Well-written and informative.",
  "Quick reference guide with examples. Perfect for daily use and learning new features.",
  "Detailed explanation of core concepts with visual diagrams and interactive examples.",
  "Collection of tips, tricks, and lesser-known features that improve productivity.",
  "Comparison of different approaches with pros and cons. Helps make informed decisions."
}

local sample_tags = {
  {"neovim", "editor", "development"},
  {"lua", "programming", "scripting"},
  {"documentation", "reference", "learning"},
  {"tutorial", "guide", "howto"},
  {"plugin", "extension", "tool"},
  {"vim", "keybindings", "commands"},
  {"git", "version-control", "workflow"},
  {"productivity", "tips", "tricks"},
  {"configuration", "settings", "dotfiles"},
  {"terminal", "cli", "shell"}
}

local sample_collections = {
  "Development",
  "Learning Resources",
  "Documentation",
  "Tutorials",
  "Tools & Utilities",
  "Unsorted",
  "Reference",
  "Best Practices"
}

-- Generate bookmarks
local bookmarks = {}
local base_time = os.time() - (86400 * 30) -- 30 days ago

for i = 1, bookmark_count do
  local title_idx = ((i - 1) % #sample_titles) + 1
  local domain_idx = ((i - 1) % #sample_domains) + 1
  local excerpt_idx = ((i - 1) % #sample_excerpts) + 1
  local tags_idx = ((i - 1) % #sample_tags) + 1
  local collection_idx = ((i - 1) % #sample_collections) + 1

  -- Generate timestamps (spread over last 30 days)
  local created_time = base_time + (i * 2000)
  local last_update_time = created_time + math.random(0, 86400 * 7)

  local created = os.date("!%Y-%m-%dT%H:%M:%S.000Z", created_time)
  local last_update = os.date("!%Y-%m-%dT%H:%M:%S.000Z", last_update_time)

  local title = sample_titles[title_idx]
  if bookmark_count > #sample_titles then
    title = title .. " #" .. i
  end

  local excerpt = sample_excerpts[excerpt_idx]
  local excerpt_clean = excerpt:gsub("[\r\n]+", " "):gsub("%s+", " ")

  table.insert(bookmarks, {
    id = string.format("%d", 100000 + i),
    title = title,
    url = "https://" .. sample_domains[domain_idx] .. "/article-" .. i,
    excerpt = excerpt,
    excerpt_clean = excerpt_clean,
    tags = sample_tags[tags_idx],
    created = created,
    lastUpdate = last_update,
    domain = sample_domains[domain_idx],
    collection = sample_collections[collection_idx]
  })
end

-- Sort by lastUpdate (newest first)
table.sort(bookmarks, function(a, b)
  return a.lastUpdate > b.lastUpdate
end)

-- Create cache data structure
local cache_data = {
  bookmarks = bookmarks,
  count = #bookmarks,
  timestamp = os.time(),
  last_updated = bookmarks[1].lastUpdate
}

-- Determine cache file location
local cache_file = vim.fn.stdpath("cache") .. "/raindrop-md/bookmarks.json"

-- Ensure directory exists
local cache_dir = vim.fn.fnamemodify(cache_file, ":h")
vim.fn.mkdir(cache_dir, "p")

-- Write cache file
local json_str = vim.json.encode(cache_data)
local file = io.open(cache_file, "w")
if not file then
  print("\nError: Could not write to " .. cache_file)
  os.exit(1)
end

file:write(json_str)
file:close()

-- Calculate file size
local stat = vim.loop.fs_stat(cache_file)
local size_kb = stat and math.floor(stat.size / 1024) or 0

print("\n✓ Generated " .. #bookmarks .. " bookmarks")
print("✓ Written to: " .. cache_file)
print("✓ File size: " .. size_kb .. " KB")
print("✓ Date range: " .. bookmarks[#bookmarks].created .. " to " .. bookmarks[1].lastUpdate)

print("\n=== Ready for Benchmarking ===")
print("\nYou can now run benchmarks:")
print("  :RaindropBenchmark")
print("  :RaindropBenchmarkFull")
print("  nvim --headless +'luafile benchmark/run_benchmarks.lua' +qa")
print("\nOr clear the cache to start fresh:")
print("  :RaindropClearCache\n")

os.exit(0)
