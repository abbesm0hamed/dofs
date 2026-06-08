return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })()
    end,
    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "tsx" },
        auto_install = true,
        highlight = { enable = true },
      })
    end,
  },
}
