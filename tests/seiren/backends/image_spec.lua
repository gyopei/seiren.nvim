describe("seiren.backends.image", function()
  it("renders a Mermaid block to a PNG with mermaid-cli", function()
    local backend = require("seiren.backends.image")
    local captured_cmd
    local captured_opts
    local writes = {}
    local deleted = {}

    local result = backend.render({
      source = "flowchart TD\n  A --> B",
    }, {
      image = {
        format = "png",
        mmdc_command = "/custom/mmdc",
      },
    }, {
      tempname = function()
        return "/tmp/seiren-image"
      end,
      writefile = function(lines, path)
        writes[path] = lines
      end,
      delete = function(path)
        table.insert(deleted, path)
      end,
      system = function(cmd, opts)
        captured_cmd = cmd
        captured_opts = opts
        return {
          wait = function()
            return {
              code = 0,
              stdout = "",
              stderr = "",
            }
          end,
        }
      end,
      plugin_root = function()
        return "/plugin"
      end,
      puppeteer_config_path = function()
        return "/plugin/scripts/puppeteer-config.json"
      end,
    })

    assert_equal(result.ok, true)
    assert_equal(result.backend, "image")
    assert_equal(result.format, "png")
    assert_equal(result.image_path, "/tmp/seiren-image.png")
    assert_deep_equal(writes["/tmp/seiren-image.mmd"], { "flowchart TD", "  A --> B" })
    assert_deep_equal(captured_cmd, {
      "/custom/mmdc",
      "-i",
      "/tmp/seiren-image.mmd",
      "-o",
      "/tmp/seiren-image.png",
      "-b",
      "white",
      "-p",
      "/plugin/scripts/puppeteer-config.json",
    })
    assert_equal(captured_opts.cwd, "/plugin")
    assert_deep_equal(deleted, { "/tmp/seiren-image.mmd" })
  end)

  it("uses plugin-local mmdc by default", function()
    local backend = require("seiren.backends.image")
    local captured_cmd

    backend.render({
      source = "flowchart TD\n  A --> B",
    }, {
      image = {
        format = "png",
      },
    }, {
      tempname = function()
        return "/tmp/seiren-image"
      end,
      writefile = function() end,
      delete = function() end,
      system = function(cmd)
        captured_cmd = cmd
        return {
          wait = function()
            return {
              code = 0,
              stdout = "",
              stderr = "",
            }
          end,
        }
      end,
      mmdc_path = function()
        return "/plugin/node_modules/.bin/mmdc"
      end,
      plugin_root = function()
        return "/plugin"
      end,
      puppeteer_config_path = function()
        return "/plugin/scripts/puppeteer-config.json"
      end,
    })

    assert_equal(captured_cmd[1], "/plugin/node_modules/.bin/mmdc")
  end)

  it("returns source fallback lines when image rendering fails", function()
    local backend = require("seiren.backends.image")

    local result = backend.render({
      source = "not mermaid",
    }, {
      image = {
        mmdc_command = "/custom/mmdc",
      },
    }, {
      tempname = function()
        return "/tmp/seiren-image"
      end,
      writefile = function() end,
      delete = function() end,
      system = function()
        return {
          wait = function()
            return {
              code = 1,
              stdout = "",
              stderr = "parse failed",
            }
          end,
        }
      end,
      plugin_root = function()
        return "/plugin"
      end,
    })

    assert_equal(result.ok, false)
    assert_equal(result.backend, "image")
    assert_equal(result.error, "parse failed")
    assert_deep_equal(result.lines, {
      "Image renderer error: parse failed",
      "",
      "```mermaid",
      "not mermaid",
      "```",
    })
  end)
end)
