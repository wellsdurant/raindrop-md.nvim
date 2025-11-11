local config = require("raindrop-md.config")
local curl = require("plenary.curl")

local M = {}

local API_BASE_URL = "https://api.raindrop.io/rest/v1"

--- Fetch all bookmarks from Raindrop.io
--- @param callback function Callback function to handle the response
function M.fetch_bookmarks(callback)
  local token = config.get("token")

  if not token or token == "" then
    vim.notify("raindrop-md: API token not configured", vim.log.levels.ERROR)
    callback({ error = "No API token" })
    return
  end

  -- Fetch all bookmarks (collection ID 0 means all bookmarks)
  local url = API_BASE_URL .. "/raindrops/0"

  curl.get(url, {
    headers = {
      ["Authorization"] = "Bearer " .. token,
      ["Content-Type"] = "application/json",
    },
    callback = vim.schedule_wrap(function(response)
      if response.status ~= 200 then
        vim.notify(
          string.format("raindrop-md: API request failed with status %d", response.status),
          vim.log.levels.ERROR
        )
        callback({ error = "API request failed", status = response.status })
        return
      end

      local ok, parsed = pcall(vim.json.decode, response.body)
      if not ok then
        vim.notify("raindrop-md: Failed to parse API response", vim.log.levels.ERROR)
        callback({ error = "JSON parse error" })
        return
      end

      -- Extract bookmarks from the response
      local bookmarks = {}
      if parsed.items then
        for _, item in ipairs(parsed.items) do
          table.insert(bookmarks, {
            id = item._id,
            title = item.title or "Untitled",
            url = item.link,
            excerpt = item.excerpt or "",
            tags = item.tags or {},
            created = item.created,
            domain = item.domain or "",
            collection = item.collection and item.collection.title or "Unsorted",
          })
        end
      end

      callback({ bookmarks = bookmarks })
    end),
  })
end

--- Fetch bookmarks with pagination support
--- @param page number Page number (default: 0)
--- @param callback function Callback function
function M.fetch_all_bookmarks_paginated(page, callback)
  page = page or 0
  local token = config.get("token")

  if not token or token == "" then
    callback({ error = "No API token" })
    return
  end

  local url = string.format("%s/raindrops/0?page=%d&perpage=50", API_BASE_URL, page)

  curl.get(url, {
    headers = {
      ["Authorization"] = "Bearer " .. token,
      ["Content-Type"] = "application/json",
    },
    callback = vim.schedule_wrap(function(response)
      if response.status ~= 200 then
        callback({ error = "API request failed", status = response.status })
        return
      end

      local ok, parsed = pcall(vim.json.decode, response.body)
      if not ok then
        callback({ error = "JSON parse error" })
        return
      end

      local bookmarks = {}
      if parsed.items then
        for _, item in ipairs(parsed.items) do
          table.insert(bookmarks, {
            id = item._id,
            title = item.title or "Untitled",
            url = item.link,
            excerpt = item.excerpt or "",
            tags = item.tags or {},
            created = item.created,
            domain = item.domain or "",
            collection = item.collection and item.collection.title or "Unsorted",
          })
        end
      end

      -- Check if there are more pages
      local has_more = parsed.count and (#bookmarks + page * 50) < parsed.count

      callback({
        bookmarks = bookmarks,
        has_more = has_more,
        total = parsed.count or 0,
      })
    end),
  })
end

return M
