return {
  {
    "chrishrb/gx.nvim",
    keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
    cmd = { "Browse" },
    init = function()
      vim.g.netrw_nogx = 1 -- disable netrw gx
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gx").setup {
        open_browser_app = "xdg-open",                    -- Specify browser app (e.g., "xdg-open" for Linux)
        open_browser_args = {},                           -- Arguments for the browser command
        handler_options = {
          search_engine = "https://google.com/search?q=", -- Custom search engine
        },
      }
    end,
  }
}
