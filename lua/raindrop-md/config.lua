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
