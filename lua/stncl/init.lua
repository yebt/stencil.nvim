local M = {}
local utils = require('stncl.utils')

--- @module stncl
--- @brief Neovim template management system with dynamic content generation

--- @class Config
--- @field templates_dir string Path to user templates directory
--- @field project_markers string[] List of project root marker files
--- @field author string Default author name
--- @field email string Default author email
--- @field handlers table<string, function> Filetype-specific handler functions

--- Set config startert
local script_path = debug.getinfo(1, 'S').source:sub(2)
local plugin_root = vim.fn.fnamemodify(script_path, ':h:h:h')
local default_templates_dir = plugin_root .. '/templates'

--- Default config
--- @type Config
local default_config = {
  templates_dir = vim.fn.stdpath('config') .. '/templates',
  project_markers = { '.git', 'package.json', 'composer.json', 'cargo.toml' },
  author = os.getenv('USER') or 'user',
  email = os.getenv('EMAIL') or 'user@example.com',
  handlers = {},
}

--- Default handler
-- local default_handler = function(context, template)
--- @return table<string, string> Key-value pairs of default replacements
local default_handler = function(_, _)
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

--- Get all available template paths for given filetype
--- @param ft string Filetype to get templates for
--- @return string[] List of full template paths
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

--- Get template names for current filetype
--- @param ft string Filetype to get template names for
--- @return string[] List of template names
local function get_template_names(ft)
  return vim.tbl_map(function(path) return vim.fn.fnamemodify(path, ':t') end, get_template_paths(ft))
end

--- Load and process template content into current buffer
--- @param tmplt_path string Full path to template file
local function load_template_content(tmplt_path)
  local content = table.concat(vim.fn.readfile(tmplt_path), '\n')

  --- @class TemplateContext
  --- @field filepath string Full path to current file
  --- @field template_name string Name of the loaded template
  --- @field filetype string Current buffer filetype
  --- @field config Config Current plugin configuration

  local context = {
    filepath = vim.fn.expand('%:p'),
    template_name = vim.fn.fnamemodify(tmplt_path, ':t'),
    filetype = vim.bo.filetype,
    config = default_config,
  }

  --- Process lua expressions
  content = content:gsub('{{_lua:(.-)}}', function(expr)
    -- local ok, res = pcall(vim.api.nvim_eval, expr)
    local ok, res = pcall(utils.safe_eval, expr)
    return ok and tostring(res) or ''
  end)

  local okm, default_filetype_replacements = pcall(require, 'stncl.handlers.' .. context.filetype)
  -- Resolve appropriate handler function
  local handler_chain = {
    default_handler,                                -- default handler
    okm and default_filetype_replacements or nil,   -- default filetype handler
    default_config.handlers[context.template_name], -- user specific template handler
    default_config.handlers[context.filetype],      -- user specific filetype handler
  }
  local replacements = {}
  for _, handler in ipairs(handler_chain) do
    if handler then
      replacements = vim.tbl_extend('force', replacements, (handler(context, tmplt_path) or {}))
    end
  end

  -- Apply all replacements
  for pattern, replacement in pairs(replacements) do
    content = content:gsub('{{' .. pattern .. '}}', replacement)
  end

  -- Process position
  local processed, cursor_pos = utils.process_cursor(content)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(processed, '\n'))

  if cursor_pos and next(cursor_pos) then vim.api.nvim_win_set_cursor(0, cursor_pos) end
end

--- Load template into current buffer
--- @param tmplt? string Optional template name to load directly
function M.load_template(tmplt)
  local ft = vim.bo.filetype
  if ft == '' then
    vim.notify('No filetype detected', vim.log.levels.WARN)
    return
  end

  local templates_for_ft = get_template_paths(ft)
  -- if not exist templates for filetype, abort
  if #templates_for_ft == 0 then
    vim.notify('No templates available for filetype: ' .. ft, vim.log.levels.INFO)
    return
  end

  if tmplt then
    for _, tmplt_path in ipairs(templates_for_ft) do
      if vim.fn.fnamemodify(tmplt_path, ':t') == tmplt then
        load_template_content(tmplt_path)
        return
      end
    end
    vim.notify('Template not found: ' .. tmplt, vim.log.levels.WARN)
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

--- Setup plugin configuration
--- @param lopts? Config Partial configuration to merge with defaults
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
      desc = 'Load template for current filetype'
    }
  )
end

return M
