local config = require("seiren.config")
local parser = require("seiren.parser")
local backends = require("seiren.backends")
local context = require("seiren.context")
local preview_window = require("seiren.preview")

local M = {}

local commands_registered = false

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

function M.preview_image()
  vim.notify("seiren.nvim image preview is not implemented yet", vim.log.levels.INFO)
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

function M.setup(user_options)
  config.setup(user_options)
  register_commands()
end

return M
