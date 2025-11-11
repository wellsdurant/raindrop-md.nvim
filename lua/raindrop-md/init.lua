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
      vim.keymap.set("i", keymaps.insert_mode, function()
        -- Check if current buffer is markdown
        if vim.bo.filetype == "markdown" then
          -- Exit insert mode first
          vim.cmd("stopinsert")
          -- Schedule the picker to run after mode change completes
          vim.schedule(function()
            M.pick_bookmark()
          end)
        else
          -- Fallback to default behavior if not in markdown
          local key = vim.api.nvim_replace_termcodes(keymaps.insert_mode, true, false, true)
          vim.api.nvim_feedkeys(key, "n", false)
        end
      end, {
        desc = "Pick Raindrop bookmark to insert",
        noremap = false,
      })
    end
  end
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
