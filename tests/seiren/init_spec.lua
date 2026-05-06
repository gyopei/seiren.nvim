describe("seiren init", function()
  it("setup registers user commands", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil

    require("seiren").setup()

    assert_truthy(vim.api.nvim_get_commands({})["SeirenPreview"])
    assert_truthy(vim.api.nvim_get_commands({})["SeirenClose"])
    assert_truthy(vim.api.nvim_get_commands({})["SeirenToggle"])
  end)
end)

