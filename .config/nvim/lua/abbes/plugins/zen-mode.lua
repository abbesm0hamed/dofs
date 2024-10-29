return {
  "folke/zen-mode.nvim",
  event = "VeryLazy",
  dependencies = {
    {
      -- Plugin for additional highlighting customization
      "folke/twilight.nvim",
      event = "VeryLazy",
      config = function()
        -- Configure custom highlights for comments
        vim.cmd([[
          " Define the custom highlight group for comments
          " highlight Comment gui=italic guifg=#6A9955 guibg=NONE

          " Specify the 'Shadows Into Light' font for comments
          " let &guifont = 'ZedMono Nerd Font:h12'

          " Enable italic comments
          let g:enable_italic_font = 1

          " Make sure vim recognizes italics
          let &t_ZH="\e[3m"
          let &t_ZR="\e[23m"
        ]])
      end
    }
  },
  keys = {
    {
      "<leader>tz",
      "<cmd>ZenMode<cr>",
      desc = "Toggle ZenMode",
    },
  },
  opts = {
    window = {
      backdrop = 1,             -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
      width = 0.70,             -- width of the Zen window
      options = {
        signcolumn = "no",      -- disable signcolumn
        number = false,         -- disable number column
        relativenumber = false, -- disable relative numbers
        cursorline = false,     -- disable cursorline
        cursorcolumn = false,   -- disable cursor column
      },
    },
    -- callback where you can add custom code when the Zen window opens
    on_open = function(win)
      vim.opt["conceallevel"] = 3
      vim.opt["concealcursor"] = "nc"
    end,
    -- callback where you can add custom code when the Zen window closes
    on_close = function()
      vim.opt["conceallevel"] = 0
      vim.opt["concealcursor"] = ""
    end,
  },
}
