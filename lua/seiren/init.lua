local config = require("seiren.config")

local M = {}

local commands_registered = false

function M.preview()
  vim.notify("seiren.nvim preview is not implemented yet", vim.log.levels.INFO)
end

function M.close()
  vim.notify("seiren.nvim close is not implemented yet", vim.log.levels.INFO)
end

function M.toggle()
  vim.notify("seiren.nvim toggle is not implemented yet", vim.log.levels.INFO)
end

local function register_commands()
  if commands_registered then
    return
  end

  vim.api.nvim_create_user_command("SeirenPreview", function()
    M.preview()
  end, { desc = "Preview Mermaid diagram context" })

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

