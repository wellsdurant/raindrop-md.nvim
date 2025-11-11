local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")

local cache = require("raindrop-md.cache")
local config = require("raindrop-md.config")

local M = {}

-- Store active picker for status updates
local active_picker = nil
local status_timer = nil

--- Insert bookmark link at cursor position
--- @param bookmark table
--- @param win number Window handle
--- @param buf number Buffer handle
--- @param row number Row position
--- @param col number Column position
local function insert_bookmark(bookmark, win, buf, row, col)
  local markdown_link = string.format("[%s](%s)", bookmark.title, bookmark.url)

  -- Validate window and buffer are still valid
  if not vim.api.nvim_win_is_valid(win) then
    vim.notify("raindrop-md: Invalid window", vim.log.levels.ERROR)
    return
  end

  if not vim.api.nvim_buf_is_valid(buf) then
    vim.notify("raindrop-md: Invalid buffer", vim.log.levels.ERROR)
    return
  end

  -- Get current line
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""

  -- Insert link after cursor position (we're in normal mode, cursor is ON a character)
  local new_line = line:sub(1, col + 1) .. markdown_link .. line:sub(col + 2)
  vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })

  -- Calculate new cursor position and ensure it's within bounds
  local new_col = col + 1 + #markdown_link
  local max_col = #new_line
  if new_col > max_col then
    new_col = max_col
  end

  -- Move cursor to end of inserted text
  pcall(vim.api.nvim_win_set_cursor, win, { row, new_col })

  -- Return to insert mode one position after the bookmark
  vim.cmd("startinsert!")
end

--- Create entry display for telescope picker
--- @param bookmark table
--- @return table
local function make_display(bookmark)
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 50 },
      { width = 40 },
      { remaining = true },
    },
  })

  -- Get excerpt or use empty string
  local excerpt = bookmark.excerpt or ""

  return displayer({
    { bookmark.title, "TelescopeResultsIdentifier" },
    { bookmark.url, "TelescopeResultsComment" },
    { excerpt, "TelescopeResultsNumber" },
  })
end

--- Update picker prompt title with status
--- @param picker table Telescope picker instance
--- @param status string Status message
local function update_picker_status(picker, status)
  if picker and picker.prompt_border then
    picker.prompt_border:change_title(status)
  end
end

--- Open telescope picker for bookmarks
--- @param opts table|nil Options for telescope picker
function M.pick_bookmark(opts)
  opts = opts or {}

  -- Check if current buffer is a markdown file
  local filetype = vim.bo.filetype
  if filetype ~= "markdown" then
    vim.notify(
      "raindrop-md: This command only works in markdown files",
      vim.log.levels.WARN
    )
    return
  end

  -- Capture the original window and cursor position BEFORE opening telescope
  local original_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_get_current_buf()
  local original_cursor = vim.api.nvim_win_get_cursor(original_win)

  -- Status callback for cache updates
  local status_callback = function(status)
    if active_picker then
      update_picker_status(active_picker, status)
    end
  end

  cache.get_bookmarks(opts.force_refresh or false, function(bookmarks)
    if not bookmarks or #bookmarks == 0 then
      vim.notify("raindrop-md: No bookmarks found", vim.log.levels.WARN)
      return
    end

    -- Sort bookmarks by modification time (newest first)
    table.sort(bookmarks, function(a, b)
      local a_time = a.lastUpdate or a.created or ""
      local b_time = b.lastUpdate or b.created or ""
      return a_time > b_time
    end)

    local telescope_opts = vim.tbl_deep_extend("force", config.get("telescope_opts"), opts)
    local base_title = telescope_opts.prompt_title

    local picker = pickers
      .new(telescope_opts, {
        prompt_title = base_title,
        finder = finders.new_table({
          results = bookmarks,
          entry_maker = function(entry)
            return {
              value = entry,
              display = function(e)
                return make_display(e.value)
              end,
              ordinal = entry.title .. " " .. entry.url .. " " .. (entry.excerpt or ""),
            }
          end,
        }),
        sorter = conf.generic_sorter(telescope_opts),
        previewer = previewers.new_buffer_previewer({
          title = "Bookmark Details",
          define_preview = function(self, entry)
            local bookmark = entry.value
            local lines = {
              "Title: " .. bookmark.title,
              "URL: " .. bookmark.url,
              "Domain: " .. bookmark.domain,
              "Collection: " .. bookmark.collection,
              "",
            }

            if bookmark.excerpt and bookmark.excerpt ~= "" then
              table.insert(lines, "Excerpt:")
              table.insert(lines, bookmark.excerpt)
              table.insert(lines, "")
            end

            if bookmark.tags and #bookmark.tags > 0 then
              table.insert(lines, "Tags: " .. table.concat(bookmark.tags, ", "))
              table.insert(lines, "")
            end

            if bookmark.created then
              local date = os.date("%Y-%m-%d %H:%M:%S", tonumber(bookmark.created))
              table.insert(lines, "Created: " .. date)
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            if selection then
              -- Use the captured original window/buffer/cursor from before picker opened
              -- Double schedule to ensure telescope cleanup is completely done
              vim.schedule(function()
                vim.schedule(function()
                  insert_bookmark(selection.value, original_win, original_buf, original_cursor[1], original_cursor[2])
                end)
              end)
            end
          end)

          return true
        end,
      })

    -- Store picker reference for status updates
    active_picker = picker

    -- Register status callback with cache
    cache.register_status_callback(status_callback)

    -- Clear active picker when closed
    vim.api.nvim_create_autocmd("WinClosed", {
      once = true,
      callback = function()
        active_picker = nil
        cache.unregister_status_callback()
      end,
    })

    picker:find()
  end, status_callback)
end

return M
