local M = {}

local config = require("raindrop-md.config")
local telescope = require("raindrop-md.telescope")
local cache = require("raindrop-md.cache")

--- Setup function to initialize the plugin
--- @param opts table|nil Configuration options
function M.setup(opts)
  config.setup(opts)
end

--- Pick a bookmark using Telescope
--- @param opts table|nil Options for the picker
function M.pick_bookmark(opts)
  telescope.pick_bookmark(opts)
end

--- Refresh bookmarks from Raindrop.io API
function M.refresh_bookmarks()
  cache.get_bookmarks(true, function(bookmarks)
    vim.notify(
      string.format("raindrop-md: Refreshed %d bookmarks", #bookmarks),
      vim.log.levels.INFO
    )
  end)
end

--- Clear cached bookmarks
function M.clear_cache()
  cache.clear()
end

return M
