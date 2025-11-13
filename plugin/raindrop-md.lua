if vim.g.loaded_raindrop_md then
  return
end
vim.g.loaded_raindrop_md = 1

-- Create user commands
vim.api.nvim_create_user_command("RaindropPick", function(opts)
  require("raindrop-md").pick_bookmark({ force_refresh = opts.bang })
end, {
  desc = "Pick a Raindrop bookmark to insert (use ! to force refresh)",
  bang = true,
})

vim.api.nvim_create_user_command("RaindropRefresh", function()
  require("raindrop-md").refresh_bookmarks()
end, {
  desc = "Refresh bookmarks from Raindrop.io",
})

vim.api.nvim_create_user_command("RaindropClearCache", function()
  require("raindrop-md").clear_cache()
end, {
  desc = "Clear cached bookmarks",
})

-- Benchmark commands
vim.api.nvim_create_user_command("RaindropBenchmark", function()
  require("raindrop-md.benchmark_cmd").quick_benchmark()
end, {
  desc = "Run quick benchmark of raindrop-md operations",
})

vim.api.nvim_create_user_command("RaindropBenchmarkFull", function()
  require("raindrop-md.benchmark_cmd").run_full_benchmark()
end, {
  desc = "Run full benchmark suite",
})
