local M = {}

local state = {
  bufnr = nil,
  winid = nil,
}

local function valid_buf()
  return state.bufnr ~= nil and vim.api.nvim_buf_is_valid(state.bufnr)
end

local function valid_win()
  return state.winid ~= nil and vim.api.nvim_win_is_valid(state.winid)
end

local function ensure_buffer()
  if valid_buf() then
    return state.bufnr
  end

  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = state.bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = state.bufnr })
  vim.api.nvim_buf_set_name(state.bufnr, "seiren-preview")
  vim.diagnostic.enable(false, { bufnr = state.bufnr })

  return state.bufnr
end

local function window_options(preview)
  preview = preview or {}
  local float = preview.float or {}
  local columns = vim.o.columns
  local lines = vim.o.lines
  local width = preview.width or math.max(20, math.floor(columns * 0.8))
  local height = preview.height or math.max(8, math.floor(lines * 0.8))

  return {
    relative = float.relative or "editor",
    style = "minimal",
    border = float.border or "rounded",
    width = width,
    height = height,
    row = float.row or math.floor((lines - height) / 2),
    col = float.col or math.floor((columns - width) / 2),
    anchor = float.anchor,
  }
end

local function normalize_lines(lines)
  local normalized = {}

  for _, item in ipairs(lines or {}) do
    item = tostring(item):gsub("\r\n", "\n")
    for line in (item .. "\n"):gmatch("(.-)\n") do
      table.insert(normalized, line)
    end
  end

  return normalized
end

function M.open(lines, options)
  options = options or {}
  local preview = options.preview or {}
  local bufnr = ensure_buffer()
  local win_options = window_options(preview)

  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, normalize_lines(lines))
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

  if valid_win() then
    vim.api.nvim_win_set_config(state.winid, win_options)
    if preview.focus ~= false then
      vim.api.nvim_set_current_win(state.winid)
    end
  else
    state.winid = vim.api.nvim_open_win(bufnr, preview.focus ~= false, win_options)
    vim.keymap.set("n", "q", function()
      M.close()
    end, { buffer = bufnr, silent = true, nowait = true })
  end

  vim.api.nvim_set_option_value("wrap", preview.wrap == true, { win = state.winid })
end

function M.close()
  if valid_win() then
    vim.api.nvim_win_close(state.winid, true)
  end
  state.winid = nil
end

function M.is_open()
  return valid_win()
end

function M.get_bufnr()
  return state.bufnr
end

function M.get_winid()
  return state.winid
end

return M
