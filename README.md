# Stencil.nvim 🖋️

Neovim plugin for smart template management with dynamic content generation

## Demo

In this demo show how insert a php class php preset

![stencil-nvim](https://github.com/user-attachments/assets/5b882ad2-c892-4646-bf6e-fff7e5dd33d5)

## Features ✨

- Filetype-specific template handling
- Dynamic variable substitution
- Project-aware context resolution
- Custom handler system
- Cursor position marking
- Lua expression evaluation
- Priority-based template resolution

## Installation 📦

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yebt/stencil.nvim',
  config = function()
    require('stncl').setup({
      -- Your configuration here
    })
  end
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yebt/stencil.nvim',
  lazy = true,
  cmd = {'Stencil'},
  config = function()
    require('stncl').setup({
      -- Your configuration here
    })
  end
}
```

## Configuration ⚙️

Basic setup with PHP handlers:

```lua
require('stncl').setup({
  templates_dir = vim.fn.stdpath('config') .. '/templates',
  project_markers = { '.git', 'composer.json' },
  author = "Your Name",
  email = "your@email.com",
  handlers = {
    php = require('stncl.handlers.php') -- PHP-specific handlers
  }
})
```

Default Configuration Values

```lua
{
  templates_dir = "$XDG_CONFIG_HOME/nvim/templates",
  project_markers = { '.git', 'package.json', 'composer.json', 'cargo.toml' },
  author = os.getenv('USER') or 'user',
  email = os.getenv('EMAIL') or 'user@example.com',
  handlers = {},
}
```

## Usage 🚀

Create template directory: `mkdir -p ~/.config/nvim/templates/{filetype}`

Add templates (e.g., `~/.config/nvim/templates/php/class.php`)

Execute command in new buffer: `:Stencil`

### Template Example (php/class.php)

```php
<?php
namespace {{namespace}};

class {{class_name}}
{
    {{_cursor_}}
}
```

## Custom Handlers 🛠️

Create handlers for dynamic content generation:

```lua
-- lua/custom/handlers/python.lua
local utils = require('stncl.utils')

--- Python class handler
--- @param context table Execution context
--- @return table Key-value replacements
return function(context)
  local class_name = utils.snake_to_camel(vim.fn.expand('%:t:r'))
  return {
    module_name = class_name:lower(),
    class_name = class_name,
    author = context.config.author
  }
end
```

Register your handler:

```lua
require('stncl').setup({
  handlers = {
    python = require('custom.handlers.python')
  }
})
```

## Template Syntax 📝

Variables
`{{variable}}`: Simple substitution

`{{_lua:vim.fn.expand("%:t")}}`: Lua expression evaluation

`{{_cursor_}}`: Set cursor position

Built-in Variables
`_date_`: Current date (configurable format)

`_file_name_`: Current filename

`_author_`: Configured author name

`_email_`: Configured email

`_os_`: Current operating system

## Contributing 🤝

Fork the repository

Create feature branch

Submit PR with description

## License 📄

MIT License - See [LICENSE](LICENSE) for more details
