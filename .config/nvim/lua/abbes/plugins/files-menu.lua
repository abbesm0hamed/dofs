return {
  { "nvchad/volt" },
  {
    "nvchad/menu",
    config = function()
      -- Keyboard users
      vim.keymap.set("n", "<C-n>", function()
        require("menu").open("default")
      end, { noremap = true, silent = true })

      -- Mouse users + NvimTree users
      vim.keymap.set("n", "<RightMouse>", function()
        vim.cmd.normal({ args = { "<RightMouse>" } })

        local options = vim.bo.filetype == "NvimTree" and "nvimtree" or "default"
        require("menu").open(options, { mouse = true })
      end, { noremap = true, silent = true })
    end,
  },
}
