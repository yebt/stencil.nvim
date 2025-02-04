local M = {}
local utils = require('stncl.utils')

--- Set config startert
local script_path = debug.getinfo(1, 'S').source:sub(2)
local plugin_root = vim.fn.fnamemodify(script_path, ':h:h:h')
local default_templates_dir = plugin_root .. '/templates'

--- Default config
local default_config = {
  templates_dir = vim.fn.stdpath('config') .. '/templates',
  project_markers = { '.git', 'package.json', 'composer.json', 'cargo.toml' },
  author = os.getenv('USER') or 'user',
  email = os.getenv('EMAIL') or 'user@example.com',
  handlers = {},
}

--- Default handler
-- local default_handler = function(context, template)
local default_handler = function()
  return {
    -- _date_ = os.date('%Y-%m-%d'),
    _date_ = utils.format_date(),
    _file_name_ = vim.fn.expand('%:t'),
    _upper_file_ = vim.fn.expand('%:t:r'):upper(),
    _camel_case_file_ = utils.snake_to_camel(vim.fn.expand('%:t:r')),
    _author_ = default_config.author,
    _email_ = default_config.email,
    _variable_ = utils.to_variable_name(vim.fn.expand('%:t:r')),
    _os_ = utils.get_os(),
  }
end

local function get_template_paths(ft)
  local user_templates = vim.fn.glob(default_config.templates_dir .. '/' .. ft .. '/*', false, true)
  local default_templates = vim.fn.glob(default_templates_dir .. '/' .. ft .. '/*', false, true)

  local available_templates = {}
  local seen = {}

  -- Check templates for user
  for _, path in ipairs(user_templates) do
    local name = vim.fn.fnamemodify(path, ':t')
    if not seen[name] then
      table.insert(available_templates, path)
      seen[name] = true
    end
  end

  -- Add default templates
  for _, path in ipairs(default_templates) do
    local name = vim.fn.fnamemodify(path, ':t')
    if not seen[name] then
      table.insert(available_templates, path)
      seen[name] = true
    end
  end

  return available_templates
end

--- Get template names from filetype
local function get_template_names(ft)
  return vim.tbl_map(function(path) return vim.fn.fnamemodify(path, ':t') end, get_template_paths(ft))
end

--- Function to load template content
local function load_template_content(tmplt_path)
  local content = table.concat(vim.fn.readfile(tmplt_path), '\n')
  local context = {
    fileapth = vim.fn.expand('%:p'),
    template_name = vim.fn.fnamemodify(tmplt_path, ':t'),
    filetype = vim.bo.filetype,
  }

  --- Process lua expressions
  content = content:gsub('{{_lua:(.-)}}', function(expr)
    local ok, res = pcall(vim.api.nvim_eval, expr)
    return ok and res or ''
  end)

  --- Select handlers
  local handlers = default_config.handlers[context.template_name] or default_config.handlers[context.filetype] or nil

  local default_replacements = default_handler()
  local user_replacements = handlers and handlers(context, template_path) or {}

  -- expand default replacements with the user replacements
  local replacements = vim.tbl_extend('force', default_replacements, user_replacements)

  --- Process handlers
  for pattern, replacement in pairs(replacements) do
    content = content:gsub('{{' .. pattern .. '}}', replacement)
  end

  -- Process position
  local processed, cursor_pos = utils.process_cursor(content)
  vim.notify(vim.inspect({
    processed = processed,
    cursor_pos = cursor_pos,
  }))

  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(processed, '\n'))
  if cursor_pos then vim.api.nvim_win_set_cursor(0, cursor_pos) end
  -- if cursor_pos then vim.api.nvim_win_set_cursor(0, { cursor_pos, 0 }) end
end

--[[
-- tmplt: template string name
--]]
function M.load_template(tmplt)
  local ft = vim.bo.filetype
  if ft == '' then return end

  local templates_for_ft = get_template_paths(ft)
  -- if not exist templates for filetype, abort
  if #templates_for_ft == 0 then return end

  if tmplt then
    for _, tmplt_path in ipairs(templates_for_ft) do
      if vim.fn.fnamemodify(tmplt_path, ':t') == tmplt then
        load_template_content(tmplt_path)
        break
      end
    end
  else
    -- Select template
    vim.ui.select(templates_for_ft, {
      prompt = 'Select template',
      format_item = function(pth)
        local name = vim.fn.fnamemodify(pth, ':t')
        -- local source = path:find(config.)
        return string.format('%s', name)
      end,
    }, function(selected_itm) load_template_content(selected_itm) end)
  end
end

-- TODO:
-- Allow wildcards
-- Allow put cursor position
-- Allow put handlers
-- Allow resolve templates by ft

function M.setup(lopts)
  default_config = vim.tbl_deep_extend('force', default_config, lopts or {})

  -- Command to select template
  vim.api.nvim_create_user_command(
    'Stencil',
    function(opts) M.load_template(opts.args ~= '' and opts.args or nil) end,
    {
      nargs = '?',
      complete = function(_, cmd_line)
        return vim.tbl_filter(
          function(elm) return elm:match('^' .. (cmd_line:match('%S+$') or '')) end,
          get_template_names(vim.bo.filetype)
        )
      end,
    }
  )
end

return M
