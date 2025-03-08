return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    init = function(plugin)
      -- Load treesitter only when needed
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
        init = function()
          -- disable rtp plugin, as we only need its queries for mini.ai
          require("lazy.core.loader").disable_rtp_plugin("nvim-treesitter-textobjects")
        end,
      },
    },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>", desc = "Decrement Selection", mode = "x" },
    },
    opts = function()
      -- Create a file extension detection cache
      local extension_cache = {}

      -- Helper function to check if files of a certain type exist (with caching)
      local function has_files(extension)
        if extension_cache[extension] ~= nil then
          return extension_cache[extension]
        end
        local result = vim.fn.empty(vim.fn.glob("*." .. extension)) == 0
        extension_cache[extension] = result
        return result
      end

      -- Helper function to check if a command exists (with caching)
      local command_cache = {}
      local function have(cmd)
        if command_cache[cmd] ~= nil then
          return command_cache[cmd]
        end
        local result = vim.fn.executable(cmd) == 1
        command_cache[cmd] = result
        return result
      end

      -- Add custom filetype detection
      vim.filetype.add({
        extension = {
          rasi = "rasi",
          rofi = "rasi",
          wofi = "rasi",
        },
        filename = {
          ["vifmrc"] = "vim",
        },
        pattern = {
          -- Config files
          [".*/sway/config"] = "swayconfig",
          [".*/waybar/config"] = "jsonc",
          [".*/mako/config"] = "dosini",
          [".*/kitty/.+%.conf"] = "kitty",
          -- Environment files
          ["%.env.*"] = "sh",
          ["%.env%.[%w_.-]+"] = "sh",
        },
      })

      -- Register bash parser for kitty config
      vim.treesitter.language.register("bash", "kitty")

      -- Base configuration
      local config = {
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        sync_install = false,
        ensure_installed = {
          -- Always installed languages
          "vim",
          "vimdoc",
          "lua",
          "luadoc",
          "luap",
          "query",
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
      }

      -- Map formatters/linters to parsers for better integration
      local formatter_parser_map = {
        -- JavaScript ecosystem
        ["biome"] = { "javascript", "typescript", "tsx" },
        ["prettier"] = { "javascript", "typescript", "tsx", "html", "css", "yaml", "json", "jsonc", "markdown" },
        ["eslint"] = { "javascript", "typescript", "tsx" },
        -- Other languages
        ["stylua"] = { "lua" },
        ["black"] = { "python" },
        ["isort"] = { "python" },
        ["flake8"] = { "python" },
        ["gofumpt"] = { "go" },
        ["goimports"] = { "go" },
        ["golangci_lint"] = { "go" },
        ["rustfmt"] = { "rust" },
        ["shellcheck"] = { "bash" },
        ["shfmt"] = { "bash" },
        ["markdownlint"] = { "markdown", "markdown_inline" },
      }

      -- Check formatters/linters and add corresponding parsers
      local formatters_to_check = {
        "biome",
        "prettier",
        "eslint",
        "stylua",
        "black",
        "isort",
        "gofumpt",
        "goimports",
        "rustfmt",
        "shellcheck",
        "shfmt",
      }

      for _, formatter in ipairs(formatters_to_check) do
        if have(formatter) and formatter_parser_map[formatter] then
          for _, parser in ipairs(formatter_parser_map[formatter]) do
            table.insert(config.ensure_installed, parser)
          end
        end
      end

      -- Conditional language installations with more efficient checking
      local conditional_languages = {
        { exts = { "js", "jsx", "mjs" }, parser = { "javascript", "jsdoc" } },
        { exts = { "ts", "tsx" }, parser = { "typescript", "tsx" } },
        { exts = { "vue" }, parser = { "vue" } },
        { exts = { "astro" }, parser = { "astro" } },
        { exts = { "go", "mod", "sum", "work" }, parser = { "go", "gomod", "gosum", "gowork" } },
        { exts = { "rs" }, parser = { "rust" } },
        { exts = { "py" }, parser = { "python" } },
        { exts = { "html" }, parser = { "html" } },
        { exts = { "json", "jsonc" }, parser = { "json", "jsonc" } },
        { exts = { "toml" }, parser = { "toml" } },
        { exts = { "yaml", "yml" }, parser = { "yaml" } },
        { exts = { "md", "markdown" }, parser = { "markdown", "markdown_inline" } },
        { exts = { "sh", "bash", "zsh" }, parser = { "bash" } },
        { exts = { "dockerfile", "Dockerfile" }, parser = { "dockerfile" } },
        -- Add rasi if rofi or wofi is installed
        {
          exts = { "rasi" },
          parser = { "rasi" },
          check = function()
            return have("rofi") or have("wofi")
          end,
        },
      }

      -- Add languages if corresponding files exist
      for _, lang in ipairs(conditional_languages) do
        -- If there's a check function, use it
        if lang.check and lang.check() then
          for _, parser in ipairs(lang.parser) do
            table.insert(config.ensure_installed, parser)
          end
        else
          -- Otherwise check file extensions
          for _, ext in ipairs(lang.exts) do
            if has_files(ext) then
              for _, parser in ipairs(lang.parser) do
                table.insert(config.ensure_installed, parser)
              end
              break
            end
          end
        end
      end

      -- Check for specific config files
      local config_files = {
        -- Use bash parser for config files since it handles shell-like syntax well
        { pattern = ".*/sway/config", parser = "bash" },
        { pattern = ".*/kitty/.+%.conf", parser = "bash" },
        { pattern = "%.env.*", parser = "bash" },
      }

      for _, cfg in ipairs(config_files) do
        if vim.fn.empty(vim.fn.glob(cfg.pattern)) == 0 then
          table.insert(config.ensure_installed, cfg.parser)
        end
      end

      return config
    end,
    config = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        -- Deduplicate the ensure_installed list
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

      -- Setup parser install on new file types
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local ft = vim.bo.filetype
          -- Check if we need to install parsers for this filetype
          local parsers = require("nvim-treesitter.parsers")
          if parsers.get_parser_configs()[ft] and not parsers.has_parser(ft) then
            vim.defer_fn(function()
              vim.cmd("TSInstall " .. ft)
            end, 1000) -- Delay to avoid disrupting workflow
          end
        end,
      })
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
  {
    "windwp/nvim-ts-autotag",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "InsertEnter", -- More specific than VeryLazy for better performance
    opts = {
      autotag = {
        enable = true,
        enable_rename = true,
        enable_close = true,
        enable_close_on_slash = true,
        filetypes = {
          "html",
          "xml",
          "jsx",
          "tsx",
          "javascriptreact",
          "typescriptreact",
          "svelte",
          "vue",
          "astro",
          "php",
          "markdown",
        },
      },
    },
  },
  -- {
  --   "nvim-treesitter/nvim-treesitter-context",
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  --   event = "BufReadPost",
  --   keys = {
  --     {
  --       "gk",
  --       function()
  --         require("treesitter-context").go_to_context()
  --       end,
  --       desc = " Goto Context",
  --     },
  --   },
  --   opts = {
  --     max_lines = 4,
  --     multiline_threshold = 1, -- only show 1 line per context
  --     -- Optimize performance by checking filetype on attach
  --     on_attach = function(bufnr)
  --       local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  --       -- Disable in specific filetypes
  --       return ft ~= "markdown" and ft ~= "help"
  --     end,
  --   },
  --   init = function()
  --     vim.api.nvim_create_autocmd("ColorScheme", {
  --       callback = function()
  --         -- adds grey underline
  --         local grey = vim.api.nvim_get_hl_by_name("Comment", true).foreground
  --         vim.api.nvim_set_hl(0, "TreesitterContextBottom", { special = grey, underline = true })
  --       end,
  --     })
  --   end,
  -- },
}
