describe("seiren.health", function()
  it("collects dependency checks", function()
    local health = require("seiren.health")

    local checks = health.collect({
      mermaid = {
        node_command = "node",
        runner_path = "/project/scripts/render-beautiful-mermaid.mjs",
      },
      preview = {
        wrap = true,
      },
    }, {
      runner_path = function()
        return "/project/scripts/render-beautiful-mermaid.mjs"
      end,
      plugin_root = function()
        return "/project"
      end,
      executable = function(command)
        assert_equal(command, "node")
        return 1
      end,
      filereadable = function(path)
        assert_equal(path, "/project/scripts/render-beautiful-mermaid.mjs")
        return 1
      end,
      system = function()
        return {
          wait = function()
            return {
              code = 0,
              stdout = "ok",
              stderr = "",
            }
          end,
        }
      end,
    })

    assert_equal(checks[1].status, "ok")
    assert_equal(checks[2].status, "ok")
    assert_equal(checks[3].status, "ok")
    assert_equal(checks[4].status, "warn")
  end)

  it("checks mermaid-cli when image preview is enabled", function()
    local health = require("seiren.health")

    local checks = health.collect({
      mermaid = {
        node_command = "node",
        runner_path = "/project/scripts/render-beautiful-mermaid.mjs",
      },
      image = {
        enabled = true,
      },
      preview = {
        wrap = false,
      },
    }, {
      runner_path = function()
        return "/project/scripts/render-beautiful-mermaid.mjs"
      end,
      mmdc_path = function()
        return "/project/node_modules/.bin/mmdc"
      end,
      plugin_root = function()
        return "/project"
      end,
      executable = function(command)
        if command == "node" or command == "/project/node_modules/.bin/mmdc" then
          return 1
        end
        return 0
      end,
      filereadable = function()
        return 1
      end,
      system = function()
        return {
          wait = function()
            return {
              code = 0,
              stdout = "ok",
              stderr = "",
            }
          end,
        }
      end,
    })

    assert_equal(checks[5].status, "ok")
    assert_equal(checks[5].name, "mermaid-cli")
  end)

  it("uses plugin root for the default runner path", function()
    local health = require("seiren.health")
    local checked_path

    health.collect({
      mermaid = {
        node_command = "node",
      },
      preview = {
        wrap = false,
      },
    }, {
      runner_path = function()
        return "/plugin/scripts/render-beautiful-mermaid.mjs"
      end,
      plugin_root = function()
        return "/plugin"
      end,
      executable = function()
        return 1
      end,
      filereadable = function(path)
        checked_path = path
        return 1
      end,
      system = function(_, opts)
        assert_equal(opts.cwd, "/plugin")
        return {
          wait = function()
            return {
              code = 0,
              stdout = "ok",
              stderr = "",
            }
          end,
        }
      end,
    })

    assert_equal(checked_path, "/plugin/scripts/render-beautiful-mermaid.mjs")
  end)

  it("reports missing Node and runner as errors", function()
    local health = require("seiren.health")

    local checks = health.collect({
      mermaid = {
        node_command = "node",
        runner_path = "/missing/runner.mjs",
      },
      preview = {
        wrap = false,
      },
    }, {
      runner_path = function()
        return "/missing/runner.mjs"
      end,
      mmdc_path = function()
        return "/missing/node_modules/.bin/mmdc"
      end,
      plugin_root = function()
        return "/missing"
      end,
      executable = function()
        return 0
      end,
      filereadable = function()
        return 0
      end,
      system = function()
        return {
          wait = function()
            return {
              code = 1,
              stdout = "",
              stderr = "missing package",
            }
          end,
        }
      end,
    })

    assert_equal(checks[1].status, "error")
    assert_equal(checks[2].status, "error")
    assert_equal(checks[3].status, "error")
    assert_equal(checks[4].status, "ok")
  end)
end)
