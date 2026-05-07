local M = {}

local entries = {}

local function default_delete(path)
  return vim.fn.delete(path)
end

local function delete_path(path, delete)
  if not path or path == "" then
    return
  end

  pcall(delete or default_delete, path)
end

function M.key(block, options)
  options = options or {}
  local image = options.image or {}

  return table.concat({
    block and block.source or "",
    image.renderer or "mermaid_cli",
    image.format or "png",
    image.background or "white",
    image.mmdc_command or "",
    tostring(image.puppeteer_config_path),
  }, "\0")
end

function M.get(key)
  return entries[key]
end

function M.put(key, image_path, deps)
  deps = deps or {}

  entries[key] = {
    image_path = image_path,
    delete = deps.delete or default_delete,
  }
end

function M.cleanup()
  local deleted = {}

  for _, entry in pairs(entries) do
    if entry.image_path and not deleted[entry.image_path] then
      delete_path(entry.image_path, entry.delete)
      deleted[entry.image_path] = true
    end
  end

  entries = {}
end

function M.reset()
  entries = {}
end

return M
