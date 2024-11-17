return {
  {
    "mgierada/lazydocker.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("lazydocker").setup({
        height = 0.9,
        width = 0.9,
        popup_window = {
          border = "rounded",
          title = "LazyDocker",
          title_align = "center",
        },
      })

      -- Updated command name to match the actual plugin command
      vim.keymap.set("n", "<leader>ld", "<cmd>Lazydocker<CR>", {
        silent = true,
        noremap = true,
        desc = "Open LazyDocker",
      })
    end,
  }
}
