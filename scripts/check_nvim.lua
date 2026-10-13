local function fail(message)
  io.stderr:write("nvim check: " .. message .. "\n")
  vim.cmd("cquit 1")
end

local function main()
  if vim.fn.exists(":YakiiroStrike") ~= 2 then
    fail("YakiiroStrike was not defined")
  end
  if vim.fn.exists(":YakiiroWq") ~= 2 or vim.fn.exists(":YakiiroX") ~= 2 then
    fail("write-quit commands were not defined")
  end

  local forge = require("yakiiro_forge")
  if not forge.theme_is_yakiiro() then
    fail("theme name file should read as yakiiro")
  end

  vim.cmd("enew")
  vim.bo.filetype = "markdown"
  if not forge.is_markdown() or not forge.should_forge() then
    fail("a markdown buffer on yakiiro should forge")
  end

  vim.bo.filetype = "lua"
  if forge.should_forge() then
    fail("a lua buffer should not forge")
  end

  vim.bo.filetype = "markdown"
  vim.g.colors_name = "aether"
  vim.api.nvim_set_hl(0, "markdownH1", { fg = "#FF00FF" })
  forge.apply_resting()
  local kept = vim.api.nvim_get_hl(0, { name = "markdownH1", link = false }).fg
  if kept ~= tonumber("FF00FF", 16) then
    fail("aether should keep its own markdown colors")
  end

  vim.g.colors_name = "habamax"
  forge.apply_resting()
  local fg = vim.api.nvim_get_hl(0, { name = "markdownH1", link = false }).fg
  local expect = tonumber("D4C49A", 16)
  if fg ~= expect then
    local shown = fg and string.format("#%06X", fg) or "none"
    fail("markdownH1 resting color is " .. shown .. ", expected #D4C49A")
  end

  local theme_file = vim.env.HOME .. "/.local/state/omarchy/current/theme.name"
  vim.fn.writefile({ "tokyo-night" }, theme_file)
  if forge.theme_is_yakiiro() or forge.should_forge() then
    fail("tokyo-night was treated as yakiiro")
  end

  vim.fn.delete(theme_file)
  if forge.theme_is_yakiiro() then
    fail("a missing theme name was treated as yakiiro")
  end
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
  io.stderr:write("nvim check: " .. tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
print("nvim check ok")
