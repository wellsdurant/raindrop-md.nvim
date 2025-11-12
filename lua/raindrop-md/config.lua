local M = {}

M.defaults = {
  -- Raindrop.io API token
  token = nil,
  -- Cache file location
  cache_file = vim.fn.stdpath("data") .. "/raindrop-md-cache.json",
  -- Cache expiration time in seconds (default: 1 hour)
  cache_expiration = 3600,
  -- Date format for display
  date_format = "%Y-%m-%d",
  -- Telescope picker options
  telescope_opts = {
    prompt_title = "Raindrop Bookmarks",
    layout_strategy = "horizontal",
    layout_config = {
      width = 0.8,
      height = 0.8,
      preview_width = 0.6,
    },
  },
  -- Keymaps (set to false to disable default keymaps)
  keymaps = {
    -- Insert mode keymap for picking bookmarks
    insert_mode = "<C-b>",
  },
  -- Preload bookmarks on startup for instant picker access
  preload = true,
  -- Delay in milliseconds before preloading (to avoid slowing down startup)
  preload_delay = 1000,
  -- Auto-update cache when opening markdown files
  auto_update = true,
  -- Minimum time between auto-updates in seconds (to avoid spam)
  auto_update_interval = 300, -- 5 minutes
  -- Show verbose notifications (recommended: false for less noise)
  verbose = false,
  -- Minimum time between metadata checks in seconds (avoids checking on every picker open)
  metadata_check_interval = 60, -- 1 minute
  -- API pagination size (50-250, depending on Raindrop API limits)
  pagination_size = 50,
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Validate token
  if not M.options.token or M.options.token == "" then
    vim.notify(
      "raindrop-md: No API token configured. Please set token in setup()",
      vim.log.levels.WARN
    )
  end
end

function M.get(key)
  return M.options[key]
end

return M
