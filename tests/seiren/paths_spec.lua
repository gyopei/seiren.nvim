describe("seiren.paths", function()
  it("resolves plugin files from module location instead of cwd", function()
    local paths = require("seiren.paths")

    local root = paths.plugin_root({
      source = "@/tmp/lazy/seiren.nvim/lua/seiren/paths.lua",
    })

    assert_equal(root, "/tmp/lazy/seiren.nvim")
    assert_equal(
      paths.runner_path({
        source = "@/tmp/lazy/seiren.nvim/lua/seiren/paths.lua",
      }),
      "/tmp/lazy/seiren.nvim/scripts/render-beautiful-mermaid.mjs"
    )
    assert_equal(
      paths.mmdc_path({
        source = "@/tmp/lazy/seiren.nvim/lua/seiren/paths.lua",
      }),
      "/tmp/lazy/seiren.nvim/node_modules/.bin/mmdc"
    )
  end)
end)
