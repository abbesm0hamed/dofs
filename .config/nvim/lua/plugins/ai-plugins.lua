return {
  {
    "Exafunction/codeium.nvim",
    cmd = "Codeium",
    event = "InsertEnter",
    build = ":Codeium Auth",
    config = function()
      -- Only try to set up cmp integration if cmp is actually loaded
      local has_cmp, cmp = pcall(require, "cmp")
      require("codeium").setup({
        enable_cmp_source = has_cmp and vim.g.ai_cmp,
        virtual_text = {
          enabled = not vim.g.ai_cmp,
          key_bindings = {
            accept = false,
            next = "<M-]>",
            prev = "<M-[>",
          },
        },
      })

      -- Only set up cmp source if cmp is available and enabled
      if has_cmp and vim.g.ai_cmp then
        cmp.setup.sources({
          { name = "codeium", group_index = 1, priority = 100 },
        })
      end
    end,
  },
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   build = ":Copilot auth",
  --   event = "InsertEnter",
  --   opts = {
  --     suggestion = {
  --       enabled = not vim.g.ai_cmp,
  --       auto_trigger = true,
  --       keymap = {
  --         accept = false, -- handled by nvim-cmp / blink.cmp
  --         next = "<M-]>",
  --         prev = "<M-[>",
  --       },
  --     },
  --     panel = { enabled = false },
  --     filetypes = {
  --       markdown = true,
  --       help = true,
  --     },
  --   },
  -- },
}
