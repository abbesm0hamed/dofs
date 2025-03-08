return {
  -- treesitter is configured automatically by lazyVim already
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "go", "gomod", "gowork", "gosum" } },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    enabled = true,
    config = function()
      -- If treesitter is already loaded, we need to run config again for textobjects
      if LazyVim.is_loaded("nvim-treesitter") then
        local opts = LazyVim.opts("nvim-treesitter")
        require("nvim-treesitter.configs").setup({ textobjects = opts.textobjects })
      end

      -- When in diff mode, we want to use the default
      -- vim text objects c & C instead of the treesitter ones.
      local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
      local configs = require("nvim-treesitter.configs")
      for name, fn in pairs(move) do
        if name:find("goto") == 1 then
          move[name] = function(q, ...)
            if vim.wo.diff then
              local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
              for key, query in pairs(config or {}) do
                if q == query and key:find("[%]%[][cC]") then
                  vim.cmd("normal! " .. key)
                  return
                end
              end
            end
            return fn(q, ...)
          end
        end
      end
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "LazyFile",
    opts = {},
    config = function()
      require("nvim-ts-autotag").setup({})
    end,
  },
  {
    "RRethy/nvim-treesitter-endwise",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "InsertEnter",
    opts = {
      endwise = {
        enable = true,
      },
      -- Adding required TSConfig fields
      modules = {},
      sync_install = false,
      ensure_installed = {},
      ignore_install = {},
      auto_install = true,
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  -- { -- sticky context lines at the top to show the current section of code
  --   "nvim-treesitter/nvim-treesitter-context",
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  --   event = "VeryLazy",
  --   keys = {
  --     {
  --       "gk",
  --       function()
  --         require("treesitter-context").go_to_context()
  --       end,
  --       desc = " Goto Context",
  --     },
  --   },
  --   opts = {
  --     max_lines = 4,
  --     multiline_threshold = 1, -- only show 1 line per context
  --
  --     -- disable in markdown, PENDING https://github.com/nvim-treesitter/nvim-treesitter-context/issues/289
  --     on_attach = function()
  --       vim.defer_fn(function()
  --         if vim.bo.filetype == "markdown" then
  --           return false
  --         end
  --       end, 1)
  --     end,
  --   },
  -- },
  --
  -- { -- virtual text context at the end of a scope
  --   "haringsrob/nvim_context_vt",
  --   event = "VeryLazy",
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  --   opts = {
  --     highlight = "LspInlayHint",
  --     prefix = " 󱞷",
  --     min_rows = 8,
  --     disable_ft = { "markdown", "yaml", "css" },
  --     min_rows_ft = { python = 15 },
  --     disable_virtual_lines = false,
  --   },
  -- },
}
