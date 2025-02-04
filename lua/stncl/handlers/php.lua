local utls = require('stncl.utils')

-- Resolve namespace
local function resolve_namespace(dir_part, composer_path, relative_path)
  local namespace = nil
  if vim.fn.filereadable(composer_path) == 1 then
    local content = vim.fn.readfile(composer_path)
    local ok, composerjson = pcall(vim.json.decode, table.concat(content, '\n'))
    if ok and composerjson.autoload and composerjson.autoload['psr-4'] then
      local psr4_paths = composerjson.autoload['psr-4']
      local file_dir = vim.fn.fnamemodify(relative_path, ':h') .. '/'

      -- Sort by length
      local sorted = {}
      for ns, dir in pairs(psr4_paths) do
        dir = dir:gsub('/$', '') .. '/'
        table.insert(sorted, { ns = ns, dir = dir })
      end
      table.sort(sorted, function(a, b) return #a.dir > #b.dir end)

      for _, entry in ipairs(sorted) do
        if file_dir:sub(1, #entry.dir) == entry.dir then
          local sub_dir = file_dir:sub(#entry.dir +1)
          local parts = vim.split(sub_dir, '/', { plain = true, trimempty = true })
          local processed_ns = entry.ns:gsub('\\$', '')
          table.insert(parts, 1,processed_ns)
          namespace = table.concat(parts, '\\')
          break
        end
      end
    end
  end

  if not namespace then
    local parts = vim.split(dir_part, '/', { plain = true })
    local anmespace_parts = {}
    for _, part in ipairs(parts) do
      if part ~= '' then
        table.insert(anmespace_parts, part)
      end
    end
    namespace = table.concat(anmespace_parts, '\\')
  end

  return namespace
end

-- Get replacements
return function(context, template_path)
  local replacements = {}

  -- Get the name of the class from the file
  local file_name = vim.fn.fnamemodify(context.filepath, ':t:r')

  -- Determinate the namespace
  -- stylua: ignore
  local project_root = utls.get_project_root(
    context.filepath,
    { '.git', 'composer.json' }
  )

  local composer_path = project_root .. '/composer.json'
  local relative_path = context.filepath:sub(#project_root + 2)
  local dir_part = vim.fn.fnamemodify(relative_path, ':h')


  replacements.class_name = utls.snake_to_camel(file_name)
  replacements.namespace = resolve_namespace(dir_part, composer_path, relative_path)

  return replacements
end
