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

--- Insert bookmark link at cursor position
--- @param bookmark table
local function insert_bookmark(bookmark)
  local markdown_link = string.format("[%s](%s)", bookmark.title, bookmark.url)

  -- Get current cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Get current line
  local line = vim.api.nvim_get_current_line()

  -- Insert link after cursor position (we're in normal mode, cursor is ON a character)
  local new_line = line:sub(1, col + 1) .. markdown_link .. line:sub(col + 2)
  vim.api.nvim_set_current_line(new_line)

  -- Move cursor to end of inserted text
  vim.api.nvim_win_set_cursor(0, { row, col + 1 + #markdown_link })

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

  -- Use pre-processed excerpt (cleaned during cache write)
  local excerpt = bookmark.excerpt_clean or bookmark.excerpt or ""

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

    -- Bookmarks are already pre-sorted during cache write (newest first)
    -- No need to sort again here

    local telescope_opts = vim.tbl_deep_extend("force", config.get("telescope_opts"), opts)
    local base_title = telescope_opts.prompt_title

    local picker = pickers
      .new(telescope_opts, {
        prompt_title = base_title,
        finder = finders.new_table({
          results = bookmarks,
          entry_maker = function(entry)
            -- Use pre-processed excerpt (cleaned during cache write)
            local excerpt_clean = entry.excerpt_clean or entry.excerpt or ""

            return {
              value = entry,
              display = function(e)
                return make_display(e.value)
              end,
              ordinal = entry.title .. " " .. entry.url .. " " .. excerpt_clean,
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
              -- Schedule insert_bookmark to run after Telescope fully closes
              vim.schedule(function()
                insert_bookmark(selection.value)
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
