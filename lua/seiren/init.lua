local config = require("seiren.config")
local parser = require("seiren.parser")
local backends = require("seiren.backends")
local image_backend = require("seiren.backends.image")
local image_cache = require("seiren.image_cache")
local image_overlay = require("seiren.image_overlay")
local context = require("seiren.context")
local preview_window = require("seiren.preview")
local snacks_viewer = require("seiren.viewers.snacks")

local M = {}

local commands_registered = false
local autocmds_registered = false

local function ms(start_time, end_time)
  return (end_time - start_time) / 1000000
end

local function report_image_timing(options, deps, timing)
  local image = options.image or {}
  if image.debug_timing ~= true then
    return
  end

  local notify = deps.notify or vim.notify
  notify(string.format(
    "seiren.nvim image timing: cache=%s render=%.2fms viewer=%.2fms total=%.2fms",
    timing.cache,
    timing.render_ms,
    timing.viewer_ms,
    timing.total_ms
  ), vim.log.levels.INFO)
end

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
  local source_win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local block = parser.select(0, cursor[1], options)

  if not block then
    vim.notify("seiren.nvim: no Mermaid diagram found", vim.log.levels.WARN)
    return
  end

  local renderer = deps.image_backend or image_backend
  local viewer = deps.viewer or snacks_viewer
  local hrtime = deps.hrtime or vim.uv.hrtime
  local total_start = hrtime()
  local cache_key = image_cache.key(block, options)
  local cached = image_cache.get(cache_key)
  local render_ms = 0
  local render_end = total_start
  local rendered

  if cached then
    rendered = {
      ok = true,
      image_path = cached.image_path,
    }
  else
    local render_start = hrtime()
    rendered = renderer.render(block, options)
    render_end = hrtime()
    render_ms = ms(render_start, render_end)
  end

  if not rendered.ok then
    report_image_timing(options, deps, {
      cache = cached and "hit" or "miss",
      render_ms = render_ms,
      viewer_ms = 0,
      total_ms = ms(total_start, render_end),
    })
    preview_window.open(context.format(block, rendered.lines, options), options)
    return
  end

  if not cached then
    image_cache.put(cache_key, rendered.image_path, {
      delete = deps.delete,
    })
  end

  local viewer_start = hrtime()
  local shown = viewer.show(rendered.image_path, options, {
    block = block,
    source_win = source_win,
    source_cursor = cursor,
  })
  local viewer_end = hrtime()
  report_image_timing(options, deps, {
    cache = cached and "hit" or "miss",
    render_ms = render_ms,
    viewer_ms = ms(viewer_start, viewer_end),
    total_ms = ms(total_start, viewer_end),
  })

  if shown.ok and shown.close then
    image_overlay.attach_lifecycle(source_win, cursor, {
      close = shown.close,
    })
  elseif not shown.ok then
    preview_window.open(context.format(block, {
      "Image viewer error: " .. shown.error,
      "Configure snacks.nvim image support and terminal image support, or use :SeirenPreview.",
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
