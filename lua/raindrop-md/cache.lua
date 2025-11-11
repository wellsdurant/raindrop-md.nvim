local config = require("raindrop-md.config")
local api = require("raindrop-md.api")

local M = {}

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

--- Read bookmarks from cache file
--- @return table|nil
function M.read()
  local cache_file = config.get("cache_file")

  if not is_cache_valid() then
    return nil
  end

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

  return data.bookmarks
end

--- Write bookmarks to cache file
--- @param bookmarks table
function M.write(bookmarks)
  local cache_file = config.get("cache_file")

  -- Ensure parent directory exists
  local parent_dir = vim.fn.fnamemodify(cache_file, ":h")
  vim.fn.mkdir(parent_dir, "p")

  local data = {
    bookmarks = bookmarks,
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

--- Get bookmarks (from cache or API)
--- @param force_refresh boolean Force refresh from API
--- @param callback function Callback function
function M.get_bookmarks(force_refresh, callback)
  -- Try to read from cache first
  if not force_refresh then
    local cached_bookmarks = M.read()
    if cached_bookmarks then
      callback(cached_bookmarks)
      return
    end
  end

  -- Fetch from API
  vim.notify("raindrop-md: Fetching bookmarks from Raindrop.io...", vim.log.levels.INFO)

  api.fetch_bookmarks(function(result)
    if result.error then
      vim.notify(
        "raindrop-md: Failed to fetch bookmarks: " .. (result.error or "Unknown error"),
        vim.log.levels.ERROR
      )
      -- Try to return cached data even if expired
      local cached_bookmarks = M.read()
      if cached_bookmarks then
        vim.notify("raindrop-md: Using cached bookmarks", vim.log.levels.WARN)
        callback(cached_bookmarks)
      else
        callback({})
      end
      return
    end

    local bookmarks = result.bookmarks or {}
    M.write(bookmarks)
    vim.notify(
      string.format("raindrop-md: Fetched %d bookmarks", #bookmarks),
      vim.log.levels.INFO
    )
    callback(bookmarks)
  end)
end

return M
