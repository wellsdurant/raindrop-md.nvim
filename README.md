# raindrop-md.nvim

A Neovim plugin that integrates [Raindrop.io](https://raindrop.io) bookmarks with Telescope, allowing you to quickly insert bookmark links into markdown files.

## Features

- 🔖 Fetch bookmarks from your Raindrop.io account
- 💾 Local caching for fast access
- 🔭 Beautiful Telescope picker interface
- 📝 Insert bookmarks as markdown links `[title](url)`
- 🔄 Auto-refresh and manual cache management
- ✨ Only works in markdown files (by design)

## Requirements

- Neovim >= 0.8.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- A [Raindrop.io](https://raindrop.io) account with API token

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "wellsdurant/raindrop-md.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("raindrop-md").setup({
      token = "your_raindrop_api_token_here",
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "wellsdurant/raindrop-md.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("raindrop-md").setup({
      token = "your_raindrop_api_token_here",
    })
  end,
}
```

## Getting Your API Token

1. Go to [Raindrop.io](https://raindrop.io)
2. Navigate to Settings → Integrations → For Developers
3. Click "Create new app"
4. Generate a test token
5. Copy the token and use it in your configuration

## Configuration

Here's the default configuration with all available options:

```lua
require("raindrop-md").setup({
  -- Your Raindrop.io API token (required)
  token = nil,

  -- Cache file location
  cache_file = vim.fn.stdpath("data") .. "/raindrop-md-cache.json",

  -- Cache expiration time in seconds (default: 1 hour)
  cache_expiration = 3600,

  -- Date format for display
  date_format = "%Y-%m-%d",

  -- Telescope picker options
  telescope_opts = {
    prompt_title = "Raindrop Bookmarks",
    layout_strategy = "horizontal",
    layout_config = {
      width = 0.8,
      height = 0.8,
      preview_width = 0.6,
    },
  },

  -- Keymaps (set to false to disable default keymaps)
  keymaps = {
    insert_mode = "<C-b>",  -- Ctrl+b in insert mode (default)
  },

  -- Preload bookmarks on startup for instant picker access
  preload = true,  -- (default: true)

  -- Delay in milliseconds before preloading (to avoid slowing down startup)
  preload_delay = 1000,  -- (default: 1000ms = 1 second)

  -- Auto-update cache when opening markdown files
  auto_update = true,  -- (default: true)

  -- Minimum time between auto-updates in seconds (to avoid spam)
  auto_update_interval = 300,  -- (default: 300s = 5 minutes)
})
```

## Usage

### Commands

- `:RaindropPick` - Open Telescope picker to select a bookmark
- `:RaindropPick!` - Force refresh bookmarks from API before picking
- `:RaindropRefresh` - Manually refresh bookmarks from Raindrop.io
- `:RaindropClearCache` - Clear the local bookmark cache

### Keymaps

**Default Keymap:**
- `<C-b>` (Ctrl+b) in insert mode - Pick and insert a bookmark (only works in markdown files)

**Customizing Keymaps:**

```lua
-- Customize the insert mode keymap
require("raindrop-md").setup({
  token = "your_token",
  keymaps = {
    insert_mode = "<C-k>",  -- Use Ctrl+k instead
  },
})

-- Disable default keymaps
require("raindrop-md").setup({
  token = "your_token",
  keymaps = false,  -- Disable all default keymaps
})
```

### Workflow

1. Open a markdown file in Neovim
2. Press `<C-b>` (Ctrl+b) in insert mode or run `:RaindropPick`
3. Search and select a bookmark from the Telescope picker
4. The bookmark will be inserted at your cursor as `[title](url)`

## How It Works

1. **Preload on Startup**: By default, bookmarks are preloaded 1 second after Neovim starts
2. **Auto-Update on Markdown Open**: Cache automatically updates when you open markdown files (max once per 5 minutes)
3. **Instant Access**: Telescope picker opens immediately using cached bookmarks
4. **Background Updates**: Cache checks and updates in background without blocking your work
5. **Smart Detection**: Detects both new bookmarks and modifications to existing ones
6. **Manual Refresh**: Use `:RaindropRefresh` or `:RaindropPick!` to force refresh

## Features in Detail

### Caching

- Bookmarks are automatically preloaded 1 second after startup
- Auto-updates when opening markdown files (every 5 minutes max)
- Cached locally to minimize API calls and provide instant access
- Background updates when cache is incomplete or expired
- Detects both new bookmarks and modifications
- Default cache expiration: 1 hour (configurable)
- Cache location: `~/.local/share/nvim/raindrop-md-cache.json`
- Disable auto-update by setting `auto_update = false` in config

### Telescope Integration

- Rich preview showing bookmark details
- Search by title, domain, or collection
- Shows title, domain, and collection in results
- Preview displays: title, URL, domain, collection, excerpt, tags, and creation date

### Markdown-Only

The plugin intentionally only works in markdown files to prevent accidental insertions in other file types.

## API

You can also use the plugin programmatically:

```lua
local raindrop = require("raindrop-md")

-- Setup
raindrop.setup({ token = "your_token" })

-- Pick a bookmark
raindrop.pick_bookmark()

-- Refresh bookmarks
raindrop.refresh_bookmarks()

-- Clear cache
raindrop.clear_cache()
```

## Troubleshooting

### "No API token configured" error

Make sure you've set your token in the setup function:

```lua
require("raindrop-md").setup({
  token = "your_raindrop_api_token_here",
})
```

### "API request failed" error

- Check your internet connection
- Verify your API token is valid
- Check if Raindrop.io API is accessible

### No bookmarks found

- Run `:RaindropRefresh` to force a refresh
- Check if you have bookmarks in your Raindrop.io account
- Clear cache with `:RaindropClearCache` and try again

## Similar Projects

- [browser-bookmarks.nvim](https://github.com/dhruvmanila/browser-bookmarks.nvim) - Insert browser bookmarks

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
