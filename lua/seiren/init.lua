local config = require("seiren.config")
local parser = require("seiren.parser")
local backends = require("seiren.backends")
local image_backend = require("seiren.backends.image")
local image_cache = require("seiren.image_cache")
local context = require("seiren.context")
local preview_window = require("seiren.preview")
local snacks_viewer = require("seiren.viewers.snacks")

local M = {}

local commands_registered = false
local autocmds_registered = false

function M.preview()
  local options = config.get()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local block = parser.select(0, cursor[1], options)

  if not block then
    vim.notify("seiren.nvim: no Mermaid diagram found", vim.log.levels.WARN)
    return
  end

  local rendered = backends.render(block, options)
  local lines = context.format(block, rendered.lines, options)
  preview_window.open(lines, options)
end

function M.preview_image(deps)
  deps = deps or {}

  local options = config.get()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local block = parser.select(0, cursor[1], options)

  if not block then
    vim.notify("seiren.nvim: no Mermaid diagram found", vim.log.levels.WARN)
    return
  end

  local renderer = deps.image_backend or image_backend
  local viewer = deps.viewer or snacks_viewer
  local cache_key = image_cache.key(block, options)
  local cached = image_cache.get(cache_key)
  local rendered = cached and {
    ok = true,
    image_path = cached.image_path,
  } or renderer.render(block, options)

  if not rendered.ok then
    preview_window.open(context.format(block, rendered.lines, options), options)
    return
  end

  if not cached then
    image_cache.put(cache_key, rendered.image_path, {
      delete = deps.delete,
    })
  end

  local shown = viewer.show(rendered.image_path, options)
  if not shown.ok then
    preview_window.open(context.format(block, {
      "Image viewer error: " .. shown.error,
      "",
      "Generated image: " .. rendered.image_path,
    }, options), options)
  end
end

function M.close()
  preview_window.close()
end

function M.toggle()
  if preview_window.is_open() then
    preview_window.close()
  else
    M.preview()
  end
end

local function register_commands()
  if commands_registered then
    return
  end

  vim.api.nvim_create_user_command("SeirenPreview", function()
    M.preview()
  end, { desc = "Preview Mermaid diagram context" })

  vim.api.nvim_create_user_command("SeirenPreviewImage", function()
    M.preview_image()
  end, { desc = "Preview Mermaid diagram as image" })

  vim.api.nvim_create_user_command("SeirenClose", function()
    M.close()
  end, { desc = "Close Seiren preview" })

  vim.api.nvim_create_user_command("SeirenToggle", function()
    M.toggle()
  end, { desc = "Toggle Seiren preview" })

  commands_registered = true
end

local function register_autocmds()
  if autocmds_registered then
    return
  end

  local group = vim.api.nvim_create_augroup("seiren_cleanup", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      image_cache.cleanup()
    end,
  })

  autocmds_registered = true
end

function M.setup(user_options)
  config.setup(user_options)
  register_commands()
  register_autocmds()
end

return M
