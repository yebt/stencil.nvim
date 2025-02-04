---
local M = {}
local utils = require('stncl.utils')
local default_templstes_dir = vim.fn.stdpath('config') .. '/templates'

M.config = {
  templates_dir = vim.fn.stdpath('config') .. '/templates',
  project_markers = { '.git', 'composer.json', 'package.json' },
  author = 'User Name',
  email = 'user@example.com',
  handlers = {},
  default_handler = function(context, template_name)
    return {
      _date_ = os.date('%Y-%m-%d'),
      _file_name_ = vim.fn.expand('%:t'),
      _upper_file_ = vim.fn.expand('%:t:r'):upper(),
      _camel_case_file_ = utils.snake_to_camel(vim.fn.expand('%:t:r')),
      _author_ = M.config.author,
      _email_ = M.config.email,
      _variable_ = utils.to_variable_name(vim.fn.expand('%:t:r')),
    }
  end,
}

-- Function to get available templates
local function get_available_templates()
  vim.print('get_available_templates')
  local ft = vim.bo.filetype
  if ft == '' then return {} end
  local templates_path = M.config.templates_dir .. '/' .. ft
  local templates = vim.fn.glob(templates_path .. '/*.*', false, true)

  return vim.tbl_map(function(path) return vim.fn.fnamemodify(path, ':t') end, templates)
end

--- Function to process cursor position
local function process_cursor_position(content)
  local cursor_pos = {}
  local lines = {}
  for i, line in ipairs(vim.split(content, '\n')) do
    if line:match('{{_cursor_}}') then
      cursor_pos = { i - 1, line:find('{{_cursor_}}') - 1 }
      line = line:gsub('{{_cursor_}}', '')
    end
    table.insert(lines, line)
  end
  return table.concat(lines, '\n'), cursor_pos
end

--- Function to evaluate lua expressions
local function evaluate_lua_expressions(content)
  return content:gsub('{{_lua:(.-)}}', function(expr)
    -- local ok, result = pcall(function() return loadstring('return ' .. expr)() end)
    local ok, result = pcall(function() return load('return ' .. expr)() end)
    return ok and result or ''
  end)
end

--- Function fo completion
local function complete_templates(arg_lead)
    local templates = get_available_templates()
    return vim.tbl_filter(function(name)
        return name:match('^' .. arg_lead)
    end, templates)
end

-- Function to control with command
function M.load_template(template_name)
  local ft = vim.bo.filetype
  if ft == '' then return end

  local templates_path = M.config.templates_dir .. '/' .. ft
  local allowed_templates = get_available_templates()

  local function load_selected_template(selected_path)
    local template_content = table.concat(vim.fn.readfile(selected_path), '\n')
    local context = {
      filepath = vim.fn.expand('%:p'),
      template_name = vim.fn.fnamemodify(selected_path, ':t'),
      filetype = ft,
    }

    -- Determine the handler to use
    local handler = M.config.handlers[context.template_name] or M.config.handlers[ft] or M.config.default_handler

    -- Get replacements
    local replacements = handler(context, M.config)

    --  Apply replacements
    template_content = template_content:gsub('{{_(.-)_}}', function(key) return replacements[key] or '' end)

    -- Proces embeded lua expressions
    template_content = evaluate_lua_expressions(template_content)

    -- Process cursor position
    local processed_content, cursor_pos = process_cursor_position(template_content)

    -- Insert the content in the current buffer
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(processed_content, '\n'))

    -- Set the cursor position if the marker is present
    if cursor_pos then
      vim.api.nvim_win_set_cursor(0, { cursor_pos[1] + 1, cursor_pos[2] })
      vim.cmd('startinsert')
    end
  end

  -- Select the template
  if template_name then
    -- local full_path = templates_path .. '/' .. template_name .. '.' .. ft
    local full_path = templates_path .. '/' .. template_name
    if vim.fn.filereadable(full_path) == 1 then
      load_selected_template(full_path)
    else
      vim.notify('Template not found: ' .. full_path, vim.log.levels.ERROR)
    end
  else
    vim.ui.select(
      vim.tbl_map(function(name) return { name = name, path = templates_path .. '/' .. name } end, allowed_templates),
      {
        prompt = 'Select a Template',
        format_item = function(item) return item.name end,
      },
      function(selected)
        if selected then load_selected_template(selected.path) end
      end
    )
  end
end

M.setup = function(config)
  config = vim.tbl_deep_extend('force', M.config, config or {})
  vim.api.nvim_create_user_command('Stncl', function(opts) M.load_template(opts.args ~= '' and opts.args or nil) end, {
    nargs = '?',
    complete = function(_, cmd_line) return complete_templates(cmd_line:match('%S+$')) end,
  })

  -- vim.api.nvim_create_autocmd('BufNewFile', {
  --   pattern = '*',
  --   callback = M.load_template,
  -- })
end

---
return M
