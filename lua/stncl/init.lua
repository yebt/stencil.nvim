---
local M = {}
local utils = require("stncl.utils")

M.config = {
  templates_dir = vim.fn.stdpath('config') .. '/templates',
  project_markers = { '.git', 'composer.json', 'package.json' },
  author = "User Name",
  email = "user@example.com",
  handlers = {},
  default_handler = function(context, template_name)
    return {
      _date_ = os.date("%Y-%m-%d"),
      _file_name_ = vim.fn.expand('%:t'),
      _upper_file_ = vim.fn.expand('%:t:r'):upper(),
      _camel_case_file_ = utils.snake_to_camel(vim.fn.expand('%:t:r')),
      _author_ = M.config.author,
      _email_ = M.config.email,
      _variable_ = utils.to_variable_name(vim.fn.expand('%:t:r')),
    }
  end
}

local function get_available_templates()
  local fn = vim.bo.filetype
  if ft == '' then 
    return {}
  end

  local templates_path = M.config.templates_dir .. '/'
end

M.setup = function ()
  -- vim.notify(vim.inspect(M.config.default_handler()))
  -- vim.notify(vim.inspect(utils.trim_path(M.config.templates_dir)))
end

---
return M
