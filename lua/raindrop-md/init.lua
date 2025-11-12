local M = {}

local config = require("raindrop-md.config")
local telescope = require("raindrop-md.telescope")
local cache = require("raindrop-md.cache")

-- Track last auto-update time to avoid spam
local last_auto_update = 0

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

  -- Preload bookmarks if enabled
  if config.get("preload") then
    local preload_delay = config.get("preload_delay") or 1000
    vim.defer_fn(function()
      M.preload_bookmarks()
    end, preload_delay)
  end

  -- Set up auto-update on markdown file open
  if config.get("auto_update") then
    local auto_update_interval = config.get("auto_update_interval") or 300

    vim.api.nvim_create_augroup("RaindropMdAutoUpdate", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      group = "RaindropMdAutoUpdate",
      pattern = "*.md",
      callback = function()
        local current_time = os.time()
        -- Only update if enough time has passed since last update
        if current_time - last_auto_update >= auto_update_interval then
          last_auto_update = current_time
          -- Update cache in background (non-blocking)
          vim.defer_fn(function()
            cache.auto_update()
          end, 100) -- Small delay to not block file opening
        end
      end,
    })
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

--- Preload bookmarks silently in background
function M.preload_bookmarks()
  cache.preload()
end

return M
