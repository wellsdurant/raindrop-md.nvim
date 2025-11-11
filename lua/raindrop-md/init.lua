local M = {}

local config = require("raindrop-md.config")
local telescope = require("raindrop-md.telescope")
local cache = require("raindrop-md.cache")

--- Setup function to initialize the plugin
--- @param opts table|nil Configuration options
function M.setup(opts)
  config.setup(opts)

  -- Set up keymaps
  local keymaps = config.get("keymaps")
  if keymaps and keymaps ~= false then
    if keymaps.insert_mode then
      -- Use <Cmd> mapping which works better with completion plugins
      vim.keymap.set("i", keymaps.insert_mode, "<Cmd>lua require('raindrop-md')._pick_from_insert()<CR>", {
        desc = "Pick Raindrop bookmark to insert",
        noremap = true,
        silent = true,
      })
    end
  end
end

--- Internal function to pick bookmark from insert mode
function M._pick_from_insert()
  -- Check if current buffer is markdown
  if vim.bo.filetype ~= "markdown" then
    vim.notify("raindrop-md: Only works in markdown files", vim.log.levels.WARN)
    return
  end

  -- Exit insert mode and run picker
  vim.cmd("stopinsert")
  vim.schedule(function()
    M.pick_bookmark()
  end)
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
