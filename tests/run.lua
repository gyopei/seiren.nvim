local specs = {
  "seiren.config_spec",
  "seiren.init_spec",
  "seiren.backends_spec",
  "seiren.backends.beautiful_mermaid_spec",
  "seiren.parser_spec",
  "seiren.context_spec",
  "seiren.preview_spec",
}

local failures = {}

local function fail(message)
  error(message, 2)
end

local function deep_equal(actual, expected, path)
  path = path or "value"

  if type(actual) ~= type(expected) then
    fail(string.format("%s type mismatch: got %s, expected %s", path, type(actual), type(expected)))
  end

  if type(actual) ~= "table" then
    if actual ~= expected then
      fail(string.format("%s mismatch: got %s, expected %s", path, vim.inspect(actual), vim.inspect(expected)))
    end
    return
  end

  for key, expected_value in pairs(expected) do
    deep_equal(actual[key], expected_value, path .. "." .. tostring(key))
  end

  for key in pairs(actual) do
    if expected[key] == nil then
      fail(string.format("%s has unexpected key %s", path, tostring(key)))
    end
  end
end

_G.describe = function(name, fn)
  print(name)
  fn()
end

_G.it = function(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("  ok - " .. name)
  else
    print("  not ok - " .. name)
    table.insert(failures, name .. "\n" .. tostring(err))
  end
end

_G.assert_equal = function(actual, expected)
  if actual ~= expected then
    fail(string.format("got %s, expected %s", vim.inspect(actual), vim.inspect(expected)))
  end
end

_G.assert_deep_equal = deep_equal

_G.assert_truthy = function(value)
  if not value then
    fail("expected truthy value, got " .. vim.inspect(value))
  end
end

for _, spec in ipairs(specs) do
  local ok, err = pcall(require, spec)
  if not ok then
    table.insert(failures, spec .. "\n" .. tostring(err))
  end
end

if #failures > 0 then
  print(table.concat(failures, "\n\n"))
  vim.cmd.cquit(1)
end
