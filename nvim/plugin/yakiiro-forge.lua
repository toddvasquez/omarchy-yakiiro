if vim.g.loaded_yakiiro_forge then
  return
end
vim.g.loaded_yakiiro_forge = true

require("yakiiro_forge").setup()
