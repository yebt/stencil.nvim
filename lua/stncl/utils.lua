---
local M = {}

function M.snake_to_camel(str)
    return str:gsub("_(%w)", function(c) return c:upper() end):gsub("^%l", string.upper)
end

function M.to_variable_name(str)
    return str:gsub("^(%u)", string.lower):gsub("[- ]", "_")
end

function M.get_project_root(filepath)
    return vim.fs.dirname(vim.fs.find(config.project_markers, {
        path = filepath,
        upward = true
    })[1])
end

function trim_path(filepath)
  return filepath:gsub("^" .. vim.env.HOME .. "/", "")
end

return M
