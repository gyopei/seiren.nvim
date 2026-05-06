local M = {}

local defaults = {
  preview = {
    window = "float",
    mode = "diagram_context",
    wrap = false,
    update = "manual",
    context_lines = 1,
    context_max_width = 80,
  },
  mermaid = {
    backend = "beautiful_mermaid",
    node_command = "node",
    runner_path = nil,
    prefer_unicode = true,
    japanese_label_mode = "auto",
  },
  debounce_ms = 200,
}

local options = vim.deepcopy(defaults)

function M.setup(user_options)
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_options or {})
  return options
end

function M.get()
  return vim.deepcopy(options)
end

function M.reset()
  options = vim.deepcopy(defaults)
end

return M

