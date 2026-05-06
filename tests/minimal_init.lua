vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.shadafile = "NONE"
package.path = table.concat({
  vim.fn.getcwd() .. "/lua/?.lua",
  vim.fn.getcwd() .. "/lua/?/init.lua",
  vim.fn.getcwd() .. "/tests/?.lua",
  vim.fn.getcwd() .. "/tests/?/init.lua",
  package.path,
}, ";")
