return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })()
    end,
    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = { "lua", "vim", "vimdoc" },
        highlight = { enable = true },
      })
    end,
  },
}
