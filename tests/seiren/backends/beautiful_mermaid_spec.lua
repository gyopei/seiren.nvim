describe("seiren.backends.beautiful_mermaid", function()
  it("runs the Node runner and returns rendered lines", function()
    local backend = require("seiren.backends.beautiful_mermaid")
    local captured_cmd

    local result = backend.render({
      source = "flowchart TD\n  A --> B",
    }, {
      mermaid = {
        node_command = "node-custom",
        runner_path = "/tmp/render-beautiful-mermaid.mjs",
      },
    }, {
      system = function(cmd)
        captured_cmd = cmd
        return {
          wait = function()
            return {
              code = 0,
              stdout = "A\nB\n",
              stderr = "",
            }
          end,
        }
      end,
      tempname = function()
        return "/tmp/seiren-test.mmd"
      end,
      writefile = function(lines, path)
        assert_equal(path, "/tmp/seiren-test.mmd")
        assert_deep_equal(lines, { "flowchart TD", "  A --> B" })
      end,
      delete = function(path)
        assert_equal(path, "/tmp/seiren-test.mmd")
      end,
    })

    assert_deep_equal(captured_cmd, {
      "node-custom",
      "/tmp/render-beautiful-mermaid.mjs",
      "/tmp/seiren-test.mmd",
    })
    assert_equal(result.ok, true)
    assert_equal(result.backend, "beautiful_mermaid")
    assert_deep_equal(result.lines, { "A", "B" })
  end)

  it("uses the plugin runner by default", function()
    local backend = require("seiren.backends.beautiful_mermaid")
    local captured_cmd

    backend.render({
      source = "flowchart TD\n  A --> B",
    }, {
      mermaid = {
        node_command = "node",
      },
    }, {
      system = function(cmd)
        captured_cmd = cmd
        return {
          wait = function()
            return {
              code = 0,
              stdout = "ok\n",
              stderr = "",
            }
          end,
        }
      end,
      tempname = function()
        return "/tmp/seiren-test.mmd"
      end,
      writefile = function() end,
      delete = function() end,
      runner_path = function()
        return "/plugin/scripts/render-beautiful-mermaid.mjs"
      end,
    })

    assert_deep_equal(captured_cmd, {
      "node",
      "/plugin/scripts/render-beautiful-mermaid.mjs",
      "/tmp/seiren-test.mmd",
    })
  end)

  it("runs Node from the plugin root by default", function()
    local backend = require("seiren.backends.beautiful_mermaid")
    local captured_opts

    backend.render({
      source = "flowchart TD\n  A --> B",
    }, {
      mermaid = {
        node_command = "node",
      },
    }, {
      system = function(_, opts)
        captured_opts = opts
        return {
          wait = function()
            return {
              code = 0,
              stdout = "ok\n",
              stderr = "",
            }
          end,
        }
      end,
      tempname = function()
        return "/tmp/seiren-test.mmd"
      end,
      writefile = function() end,
      delete = function() end,
      runner_path = function()
        return "/plugin/scripts/render-beautiful-mermaid.mjs"
      end,
      plugin_root = function()
        return "/plugin"
      end,
    })

    assert_equal(captured_opts.cwd, "/plugin")
  end)

  it("returns source fallback lines when rendering fails", function()
    local backend = require("seiren.backends.beautiful_mermaid")

    local result = backend.render({
      source = "not mermaid",
    }, {
      mermaid = {
        node_command = "node",
        runner_path = "/tmp/render-beautiful-mermaid.mjs",
      },
    }, {
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
      tempname = function()
        return "/tmp/seiren-test.mmd"
      end,
      writefile = function() end,
      delete = function() end,
    })

    assert_equal(result.ok, false)
    assert_equal(result.backend, "beautiful_mermaid")
    assert_equal(result.error, "parse failed")
    assert_deep_equal(result.lines, {
      "Renderer error: parse failed",
      "",
      "```mermaid",
      "not mermaid",
      "```",
    })
  end)
end)
