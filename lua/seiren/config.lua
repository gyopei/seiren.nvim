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
  image = {
    enabled = false,
    renderer = "mermaid_cli",
    viewer = "snacks",
    format = "png",
    background = "white",
    mmdc_command = nil,
    puppeteer_config_path = nil,
    debug_timing = false,
    window = {
      fit = true,
      max_width_ratio = 0.8,
      max_height_ratio = 0.8,
      min_width = 20,
      min_height = 8,
      padding = 0,
      pixels_per_cell_width = 10,
      pixels_per_cell_height = 20,
      large_image = "summary",
      min_readable_scale = 0.25,
    },
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
