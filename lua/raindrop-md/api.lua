local config = require("raindrop-md.config")
local curl = require("plenary.curl")

local M = {}

local API_BASE_URL = "https://api.raindrop.io/rest/v1"

--- Get total bookmark count without fetching all data
--- @param callback function Callback function
function M.get_bookmark_count(callback)
  local token = config.get("token")

  if not token or token == "" then
    callback({ error = "No API token" })
    return
  end

  -- Fetch first page with just 1 item to get total count
  local url = string.format("%s/raindrops/0?page=0&perpage=1", API_BASE_URL)

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

      callback({ count = parsed.count or 0 })
    end),
  })
end

--- Fetch bookmarks modified since a timestamp (incremental update)
--- @param since_timestamp string ISO 8601 timestamp
--- @param callback function Callback function
function M.fetch_bookmarks_since(since_timestamp, callback)
  local token = config.get("token")

  if not token or token == "" then
    callback({ error = "No API token" })
    return
  end

  local all_bookmarks = {}
  local total_count = 0

  -- Fetch bookmarks sorted by last update, newest first
  local function fetch_page_since(page)
    -- Sort by -lastUpdate (newest first), fetch until we hit items older than since_timestamp
    local url = string.format(
      "%s/raindrops/0?page=%d&perpage=50&sort=-lastUpdate",
      API_BASE_URL,
      page
    )

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

        total_count = parsed.count or 0
        local should_continue = false

        if parsed.items then
          for _, item in ipairs(parsed.items) do
            -- Check if this item is newer than our since_timestamp
            local item_updated = item.lastUpdate or item.created
            if item_updated and item_updated > since_timestamp then
              table.insert(all_bookmarks, {
                id = item._id,
                title = item.title or "Untitled",
                url = item.link,
                excerpt = item.excerpt or "",
                tags = item.tags or {},
                created = item.created,
                lastUpdate = item.lastUpdate,
                domain = item.domain or "",
                collection = item.collection and item.collection.title or "Unsorted",
              })
              should_continue = true
            end
          end
        end

        -- Continue fetching if we found new items and there might be more
        local fetched_count = page * 50 + (parsed.items and #parsed.items or 0)
        if should_continue and fetched_count < total_count then
          fetch_page_since(page + 1)
        else
          -- Done fetching updates
          callback({
            bookmarks = all_bookmarks,
            count = total_count,
          })
        end
      end),
    })
  end

  fetch_page_since(0)
end

--- Fetch a single page of bookmarks
--- @param page number Page number
--- @param callback function Callback function
local function fetch_page(page, callback)
  local token = config.get("token")

  if not token or token == "" then
    callback({ error = "No API token" })
    return
  end

  -- Use perpage=50 to minimize API calls
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
            lastUpdate = item.lastUpdate,
            domain = item.domain or "",
            collection = item.collection and item.collection.title or "Unsorted",
          })
        end
      end

      callback({
        bookmarks = bookmarks,
        count = parsed.count or 0,
        page = page,
      })
    end),
  })
end

--- Fetch all bookmarks from Raindrop.io with pagination
--- @param callback function Callback function to handle the response
function M.fetch_bookmarks(callback)
  local token = config.get("token")

  if not token or token == "" then
    vim.notify("raindrop-md: API token not configured", vim.log.levels.ERROR)
    callback({ error = "No API token" })
    return
  end

  local all_bookmarks = {}
  local total_count = 0

  -- Recursive function to fetch all pages
  local function fetch_next_page(page)
    fetch_page(page, function(result)
      if result.error then
        vim.notify(
          string.format("raindrop-md: API request failed: %s", result.error),
          vim.log.levels.ERROR
        )
        callback({ error = result.error })
        return
      end

      -- Add bookmarks from this page
      vim.list_extend(all_bookmarks, result.bookmarks)
      total_count = result.count

      -- Debug logging
      local fetched_count = #all_bookmarks
      vim.notify(
        string.format("raindrop-md: Fetched page %d: %d bookmarks (total: %d/%d)",
          page, #result.bookmarks, fetched_count, total_count),
        vim.log.levels.INFO
      )

      -- Check if we need to fetch more pages
      if fetched_count < total_count then
        -- Fetch next page
        fetch_next_page(page + 1)
      else
        -- All pages fetched
        vim.notify(
          string.format("raindrop-md: Completed fetching all %d bookmarks", fetched_count),
          vim.log.levels.INFO
        )
        callback({
          bookmarks = all_bookmarks,
          count = total_count
        })
      end
    end)
  end

  -- Start fetching from page 0
  fetch_next_page(0)
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
