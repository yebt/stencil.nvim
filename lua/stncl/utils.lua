local M = {}

-- Convert snake_case to camelCase
function M.snake_to_camel(str)
  return str:gsub('_(%w)', function(c) return c:upper() end):gsub('^%l', string.upper)
end

-- Generathe a valid variable name
function M.to_variable_name(str) return str:gsub('^(%u)', string.lower):gsub('[- ]', '_'):gsub('__+', '_') end

-- Detect project root
function M.get_project_root(filepath, project_markers)
  local root = vim.fs.dirname(vim.fs.find(project_markers or { '.git' }, {
    path = filepath,
    upward = true,
  })[1])

  return root or vim.fn.getcwd()
end

-- Process cursor position
function M.process_cursor(content)
  local cursor_pos = {}
  local lines = vim.split(content, '\n')

  for i, line in ipairs(lines) do
    local col = line:find('{{_cursor_}}')
    if col then
      cursor_pos = { i , col - 1 }
      lines[i] = line:gsub('{{_cursor_}}', '')
      break
    end
  end

  return table.concat(lines, '\n'), cursor_pos
end

--- Safely evaluate lua expression
function M.safe_eval(expr)
    local ok, result = pcall(function()
        return load("return "..expr)()
    end)
    return ok and result or ''
end

--- Format date
function M.format_date(format)
    return os.date(format or "%Y-%m-%d")
end

--- Get OS
function M.get_os()
    if package.config:sub(1,1) == '\\' then
        return 'windows'
    elseif vim.fn.has('macunix') == 1 then
        return 'macos'
    else
        return 'linux'
    end
end

return M
