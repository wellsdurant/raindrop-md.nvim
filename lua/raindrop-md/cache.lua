local config = require("raindrop-md.config")
local api = require("raindrop-md.api")

local M = {}

-- Track ongoing operations
local operation_in_progress = false
local operation_callbacks = {}

--- Check if cache file exists and is valid
--- @return boolean
local function is_cache_valid()
  local cache_file = config.get("cache_file")
  local expiration = config.get("cache_expiration")

  -- Check if file exists
  local stat = vim.loop.fs_stat(cache_file)
  if not stat then
    return false
  end

  -- Check if cache has expired
  local current_time = os.time()
  local cache_age = current_time - stat.mtime.sec

  return cache_age < expiration
end

--- Read cache data (includes bookmarks and metadata)
--- @return table|nil
local function read_cache_data()
  local cache_file = config.get("cache_file")

  local file = io.open(cache_file, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data or not data.bookmarks then
    return nil
  end

  return data
end

--- Read bookmarks from cache file
--- @return table|nil
function M.read()
  if not is_cache_valid() then
    return nil
  end

  local data = read_cache_data()
  if not data then
    return nil
  end

  return data.bookmarks
end

--- Write bookmarks to cache file
--- @param bookmarks table
--- @param count number|nil Total count from API
function M.write(bookmarks, count)
  local cache_file = config.get("cache_file")

  -- Ensure parent directory exists
  local parent_dir = vim.fn.fnamemodify(cache_file, ":h")
  vim.fn.mkdir(parent_dir, "p")

  local data = {
    bookmarks = bookmarks,
    count = count or #bookmarks,
    timestamp = os.time(),
  }

  local json_str = vim.json.encode(data)
  local file = io.open(cache_file, "w")
  if not file then
    vim.notify("raindrop-md: Failed to write cache file", vim.log.levels.ERROR)
    return
  end

  file:write(json_str)
  file:close()
end

--- Clear the cache file
function M.clear()
  local cache_file = config.get("cache_file")
  vim.fn.delete(cache_file)
  vim.notify("raindrop-md: Cache cleared", vim.log.levels.INFO)
end

--- Fetch all bookmarks and update cache
--- @param callback function Callback function
local function fetch_and_cache(callback)
  vim.notify("raindrop-md: Fetching all bookmarks from Raindrop.io...", vim.log.levels.INFO)

  api.fetch_bookmarks(function(result)
    if result.error then
      vim.notify(
        "raindrop-md: Failed to fetch bookmarks: " .. (result.error or "Unknown error"),
        vim.log.levels.ERROR
      )
      -- Try to return cached data even if expired
      local data = read_cache_data()
      if data and data.bookmarks then
        vim.notify("raindrop-md: Using cached bookmarks", vim.log.levels.WARN)
        callback(data.bookmarks)
      else
        callback({})
      end
      return
    end

    local bookmarks = result.bookmarks or {}
    local count = result.count or #bookmarks
    M.write(bookmarks, count)
    callback(bookmarks)
  end)
end

--- Fetch bookmarks in background (non-blocking)
--- @param silent boolean Don't show notifications
local function fetch_in_background(silent)
  if operation_in_progress then
    return
  end

  operation_in_progress = true

  if not silent then
    vim.notify("raindrop-md: Updating bookmarks in background...", vim.log.levels.INFO)
  end

  api.fetch_bookmarks(function(result)
    operation_in_progress = false

    if result.error then
      if not silent then
        vim.notify(
          "raindrop-md: Background update failed: " .. (result.error or "Unknown error"),
          vim.log.levels.WARN
        )
      end
      return
    end

    local bookmarks = result.bookmarks or {}
    local count = result.count or #bookmarks
    M.write(bookmarks, count)

    if not silent then
      vim.notify(
        string.format("raindrop-md: Updated cache with %d bookmarks", #bookmarks),
        vim.log.levels.INFO
      )
    end
  end)
end

--- Get bookmarks (from cache or API)
--- @param force_refresh boolean Force refresh from API
--- @param callback function Callback function
function M.get_bookmarks(force_refresh, callback)
  -- If force refresh, block and wait for fresh data
  if force_refresh then
    if operation_in_progress then
      table.insert(operation_callbacks, callback)
      return
    end

    operation_in_progress = true
    operation_callbacks = { callback }

    local function notify_all_callbacks(bookmarks)
      local callbacks_to_notify = operation_callbacks
      operation_in_progress = false
      operation_callbacks = {}

      for _, cb in ipairs(callbacks_to_notify) do
        cb(bookmarks)
      end
    end

    fetch_and_cache(notify_all_callbacks)
    return
  end

  -- Try to read from cache (even if expired or incomplete)
  local cache_data = read_cache_data()

  if cache_data and cache_data.bookmarks and #cache_data.bookmarks > 0 then
    local cached_count = #cache_data.bookmarks
    local stored_count = cache_data.count or cached_count

    -- Return cached data immediately
    vim.notify(
      string.format("raindrop-md: Showing %d cached bookmarks", cached_count),
      vim.log.levels.INFO
    )
    callback(cache_data.bookmarks)

    -- Check if we need to update in background
    if not is_cache_valid() then
      -- Cache expired, update in background
      fetch_in_background(false)
    else
      -- Check if cache is complete
      api.get_bookmark_count(function(result)
        if not result.error then
          local api_count = result.count or 0
          if cached_count ~= api_count or cached_count ~= stored_count then
            -- Cache incomplete, update in background
            vim.notify(
              string.format(
                "raindrop-md: Detected %d new bookmarks, updating in background...",
                api_count - cached_count
              ),
              vim.log.levels.INFO
            )
            fetch_in_background(true)
          end
        end
      end)
    end
  else
    -- No cache at all, must fetch (block)
    if operation_in_progress then
      table.insert(operation_callbacks, callback)
      return
    end

    operation_in_progress = true
    operation_callbacks = { callback }

    local function notify_all_callbacks(bookmarks)
      local callbacks_to_notify = operation_callbacks
      operation_in_progress = false
      operation_callbacks = {}

      for _, cb in ipairs(callbacks_to_notify) do
        cb(bookmarks)
      end
    end

    fetch_and_cache(notify_all_callbacks)
  end
end

return M
