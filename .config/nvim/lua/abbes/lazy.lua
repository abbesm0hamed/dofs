local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "abbes.plugins" }, { import = "abbes.plugins.lsp" } }, {
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json", -- Move lock file to writable data directory
  checker = {
    enabled = true,
    notify = true,
    frequency = 3600,
  },
  change_detection = {
    notify = true,
  },
})
