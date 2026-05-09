local M = {}

local lifecycle_group = "seiren_image_overlay"

local function default_topline(winid)
  return vim.fn.line("w0", winid)
end

local function default_textoff(winid)
  local info = vim.fn.getwininfo(winid)[1]
  return info and info.textoff or 0
end

local function default_winwidth(winid)
  return vim.api.nvim_win_get_width(winid)
end

function M.placement(block, source_win, layout, deps)
  deps = deps or {}

  local source_topline = (deps.topline or default_topline)(source_win)
  local textoff = (deps.textoff or default_textoff)(source_win)
  local text_width = math.max(1, (deps.winwidth or default_winwidth)(source_win) - textoff)
  local row = math.max(0, (block and block.start_line or source_topline) - source_topline)
  local preview = vim.deepcopy(layout and layout.preview or {})

  if preview.width then
    preview.width = math.min(preview.width, text_width)
  end

  preview.focus = false
  preview.float = {
    relative = "win",
    win = source_win,
    anchor = "SW",
    row = row,
    col = textoff,
  }

  return {
    preview = preview,
  }
end

local function same_cursor(left, right)
  return left and right and left[1] == right[1] and left[2] == right[2]
end

function M.attach_lifecycle(source_win, source_cursor, deps)
  deps = deps or {}
  local close = deps.close

  if not close or not source_win or not vim.api.nvim_win_is_valid(source_win) then
    return
  end

  local source_bufnr = vim.api.nvim_win_get_buf(source_win)
  local group = vim.api.nvim_create_augroup(lifecycle_group, { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    buffer = source_bufnr,
    callback = function()
      if not vim.api.nvim_win_is_valid(source_win) then
        close()
        return true
      end

      if vim.api.nvim_get_current_win() ~= source_win then
        return
      end

      if not same_cursor(vim.api.nvim_win_get_cursor(source_win), source_cursor) then
        close()
        return true
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "WinScrolled", "InsertEnter" }, {
    group = group,
    buffer = source_bufnr,
    callback = function()
      close()
      return true
    end,
  })
end

return M
