return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    lazy = true,
    init = function(plugin)
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        config = function()
          local move = require("nvim-treesitter.textobjects.move")
          local configs = require("nvim-treesitter.configs")
          for name, fn in pairs(move) do
            if name:find("goto") == 1 then
              move[name] = function(q, ...)
                if vim.wo.diff then
                  local config = configs.get_module("textobjects.move")[name]
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
    },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>",      desc = "Decrement Selection", mode = "x" },
    },
    opts = {
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      -- Remove the fold setting from here since you're using native folding
      -- fold = { enable = true },
      ensure_installed = {
        "go",
        "gomod",
        "gowork",
        "gosum",
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "astro",
        "typescript",
        "tsx",
        "xml",
        "json",
        "vue",
        "rust",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        -- "regex",
        "toml",
        "vim",
        "vimdoc",
        "yaml",
        "dockerfile",
      },
      ignore_install = { "regex" },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
      },
    },
    config = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        local added = {}
        opts.ensure_installed = vim.tbl_filter(function(lang)
          if added[lang] then
            return false
          end
          added[lang] = true
          return true
        end, opts.ensure_installed)
      end
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
  --   init = function()
  --     vim.api.nvim_create_autocmd("ColorScheme", {
  --       callback = function()
  --         -- adds grey underline
  --         local grey = u.getHighlightValue("Comment", "fg")
  --         vim.api.nvim_set_hl(0, "TreesitterContextBottom", { special = grey, underline = true })
  --       end,
  --     })
  --   end,
  -- },
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
  {
    "windwp/nvim-ts-autotag",
    dependencies = "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = "VeryLazy",
    opts = {},
    config = function()
      require("nvim-ts-autotag").setup({})
    end,
  },
}
