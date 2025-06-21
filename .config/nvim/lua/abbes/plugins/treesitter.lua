return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    init = function(plugin)
      -- Performance: Load treesitter queries early but lazily
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        config = function()
          -- Optimized textobjects move integration
          local move = require("nvim-treesitter.textobjects.move")
          local configs = require("nvim-treesitter.configs")

          -- Cache the original functions for better performance
          local original_functions = {}

          for name, fn in pairs(move) do
            if name:find("goto") == 1 then
              original_functions[name] = fn
              move[name] = function(q, ...)
                -- Fast path for diff mode
                if vim.wo.diff then
                  local config = configs.get_module("textobjects.move")[name]
                  if config then
                    for key, query in pairs(config) do
                      if q == query and key:find("[%]%[][cC]") then
                        vim.cmd("normal! " .. key)
                        return
                      end
                    end
                  end
                end
                return original_functions[name](q, ...)
              end
            end
          end
        end,
        init = function()
          -- Disable RTP plugin for better performance
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
      -- Performance: Create persistent caches
      local extension_cache = {}
      local command_cache = {}
      local file_check_cache = {}

      -- Optimized file existence check with caching
      local function has_files(pattern)
        if file_check_cache[pattern] ~= nil then
          return file_check_cache[pattern]
        end

        local result
        if pattern:match("%*") then
          -- Glob pattern
          result = vim.fn.empty(vim.fn.glob(pattern, 0, 1)) == 0
        else
          -- Regular file check
          result = vim.fn.filereadable(pattern) == 1 or vim.fn.isdirectory(pattern) == 1
        end

        file_check_cache[pattern] = result
        return result
      end

      -- Cached command existence check
      local function have(cmd)
        if command_cache[cmd] ~= nil then
          return command_cache[cmd]
        end
        local result = vim.fn.executable(cmd) == 1
        command_cache[cmd] = result
        return result
      end

      -- Enhanced filetype detection for better treesitter integration
      vim.filetype.add({
        extension = {
          rasi = "rasi",
          rofi = "rasi",
          wofi = "rasi",
          templ = "templ",
          gotmpl = "gotmpl",
          gohtml = "gohtml",
        },
        filename = {
          ["vifmrc"] = "vim",
          [".env"] = "sh",
          ["Dockerfile"] = "dockerfile",
          ["docker-compose.yml"] = "yaml",
          ["docker-compose.yaml"] = "yaml",
        },
        pattern = {
          -- Config files
          [".*/sway/config"] = "swayconfig",
          [".*/waybar/config"] = "jsonc",
          [".*/mako/config"] = "dosini",
          [".*/kitty/.+%.conf"] = "kitty",
          [".*/hypr/.+%.conf"] = "hyprlang",
          -- Environment and config patterns
          ["%.env%.[%w_.-]+"] = "sh",
          ["%.env%..*"] = "sh",
          [".*%.env"] = "sh",
          -- Docker patterns
          ["[Dd]ockerfile%..+"] = "dockerfile",
          ["compose%.ya?ml"] = "yaml",
          -- Justfile
          [".*/[Jj]ustfile"] = "just",
        },
      })

      -- Register language aliases for better parser usage
      local language_aliases = {
        ["bash"] = "kitty",
        ["yaml"] = "docker-compose",
        ["go"] = { "gomod", "gosum", "gowork" },
      }

      for base_lang, aliases in pairs(language_aliases) do
        if type(aliases) == "string" then
          vim.treesitter.language.register(base_lang, aliases)
        else
          for _, alias in ipairs(aliases) do
            vim.treesitter.language.register(base_lang, alias)
          end
        end
      end

      -- Base configuration optimized for Neovim 0.11
      local config = {
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
          -- Performance: disable for very large files
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
            -- Disable for files with too many lines
            return vim.api.nvim_buf_line_count(buf) > 5000
          end,
        },

        indent = {
          enable = true,
          -- Disable indent for problematic languages
          disable = { "python", "yaml" },
        },

        -- Performance: simplified incremental selection
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },

        -- Optimized textobjects configuration
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- Add jumps to jumplist
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.inner",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
              ["]A"] = "@parameter.inner",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.inner",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
              ["[A"] = "@parameter.inner",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>A"] = "@parameter.inner",
            },
          },
        },

        -- Essential parsers always installed
        ensure_installed = {
          "vim",
          "vimdoc",
          "lua",
          "luadoc",
          "luap",
          "query",
          "regex", -- Useful for many languages
          "markdown",
          "markdown_inline",
        },

        sync_install = false,
        auto_install = true, -- Auto-install missing parsers
        ignore_install = {},
      }

      -- Smart parser installation based on environment
      local smart_parsers = {
        -- Web development stack
        web = {
          condition = function()
            return has_files("*.js")
              or has_files("*.ts")
              or has_files("*.jsx")
              or has_files("*.tsx")
              or has_files("*.vue")
              or has_files("*.astro")
              or has_files("*.html")
              or has_files("*.css")
              or has_files("*.scss")
              or has_files("package.json")
              or have("node")
              or have("npm")
              or have("pnpm")
          end,
          parsers = { "javascript", "typescript", "tsx", "jsdoc", "html", "css", "scss", "json", "jsonc" },
        },

        -- Vue ecosystem
        vue = {
          condition = function()
            return has_files("*.vue") or has_files("vue.config.js")
          end,
          parsers = { "vue" },
        },

        -- React ecosystem
        react = {
          condition = function()
            return has_files("*.jsx") or has_files("*.tsx")
          end,
          parsers = { "tsx" },
        },

        -- Astro
        astro = {
          condition = function()
            return has_files("*.astro") or has_files("astro.config.*")
          end,
          parsers = { "astro" },
        },

        -- Go development
        go = {
          condition = function()
            return has_files("*.go") or has_files("go.mod") or has_files("go.sum") or have("go")
          end,
          parsers = { "go", "gomod", "gosum", "gowork", "templ" },
        },

        -- Rust development
        rust = {
          condition = function()
            return has_files("*.rs") or has_files("Cargo.toml") or has_files("Cargo.lock") or have("cargo")
          end,
          parsers = { "rust", "toml" },
        },

        -- Python development
        python = {
          condition = function()
            return has_files("*.py")
              or has_files("requirements.txt")
              or has_files("pyproject.toml")
              or has_files("setup.py")
              or have("python")
              or have("python3")
          end,
          parsers = { "python", "toml" },
        },

        -- Shell scripting
        shell = {
          condition = function()
            return has_files("*.sh")
              or has_files("*.bash")
              or has_files("*.zsh")
              or has_files(".bashrc")
              or has_files(".zshrc")
          end,
          parsers = { "bash" },
        },

        -- Configuration files
        config = {
          condition = function()
            return has_files("*.yaml")
              or has_files("*.yml")
              or has_files("*.toml")
              or has_files("*.json")
              or has_files(".env*")
          end,
          parsers = { "yaml", "toml", "json", "jsonc" },
        },

        -- Docker
        docker = {
          condition = function()
            return has_files("Dockerfile*") or has_files("docker-compose.*") or has_files(".dockerignore")
          end,
          parsers = { "dockerfile", "yaml" },
        },

        -- C/C++
        cpp = {
          condition = function()
            return has_files("*.c")
              or has_files("*.cpp")
              or has_files("*.h")
              or has_files("*.hpp")
              or has_files("CMakeLists.txt")
              or has_files("Makefile")
              or have("gcc")
              or have("clang")
          end,
          parsers = { "c", "cpp", "cmake", "make" },
        },

        -- Java
        java = {
          condition = function()
            return has_files("*.java") or has_files("pom.xml") or has_files("build.gradle") or have("java")
          end,
          parsers = { "java" },
        },

        -- Window manager configs
        wm_config = {
          condition = function()
            return have("sway") or have("i3") or have("hyprland") or have("rofi") or have("wofi")
          end,
          parsers = { "rasi" },
        },
      }

      -- Add parsers based on smart detection
      for category, spec in pairs(smart_parsers) do
        if spec.condition() then
          for _, parser in ipairs(spec.parsers) do
            table.insert(config.ensure_installed, parser)
          end
        end
      end

      -- Tool-based parser installation (formatters/linters suggest language usage)
      local tool_parser_map = {
        ["biome"] = { "javascript", "typescript", "tsx", "json", "jsonc" },
        ["prettier"] = { "javascript", "typescript", "tsx", "html", "css", "yaml", "json", "jsonc", "markdown" },
        ["eslint"] = { "javascript", "typescript", "tsx" },
        ["eslint_d"] = { "javascript", "typescript", "tsx" },
        ["stylua"] = { "lua" },
        ["black"] = { "python" },
        ["isort"] = { "python" },
        ["ruff"] = { "python" },
        ["gofumpt"] = { "go" },
        ["goimports"] = { "go" },
        ["golangci-lint"] = { "go" },
        ["rustfmt"] = { "rust" },
        ["shellcheck"] = { "bash" },
        ["shfmt"] = { "bash" },
        ["markdownlint"] = { "markdown" },
        ["vale"] = { "markdown" },
      }

      -- Check for tools and add corresponding parsers
      for tool, parsers in pairs(tool_parser_map) do
        if have(tool) then
          for _, parser in ipairs(parsers) do
            table.insert(config.ensure_installed, parser)
          end
        end
      end

      return config
    end,

    config = function(_, opts)
      -- Performance: deduplicate parsers
      if type(opts.ensure_installed) == "table" then
        local seen = {}
        local unique_parsers = {}

        for _, parser in ipairs(opts.ensure_installed) do
          if not seen[parser] then
            seen[parser] = true
            table.insert(unique_parsers, parser)
          end
        end

        opts.ensure_installed = unique_parsers
      end

      require("nvim-treesitter.configs").setup(opts)

      -- Performance optimization: lazy loading for large files
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("TreesitterOptimization", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local line_count = vim.api.nvim_buf_line_count(buf)

          -- Disable some features for large files
          if line_count > 2000 then
            vim.treesitter.stop(buf)
            vim.defer_fn(function()
              if vim.api.nvim_buf_is_valid(buf) then
                vim.treesitter.start(buf)
              end
            end, 100)
          end
        end,
      })

      -- Auto-install missing parsers on filetype detection
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterAutoInstall", { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft == "" then
            return
          end

          local parsers = require("nvim-treesitter.parsers")
          local parser_config = parsers.get_parser_configs()

          -- Check if parser exists and is not installed
          if parser_config[ft] and not parsers.has_parser(ft) then
            vim.notify(string.format("Installing treesitter parser for %s", ft), vim.log.levels.INFO)
            vim.cmd("TSInstall " .. ft)
          end
        end,
      })

      -- Performance: optimize treesitter for editing
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = vim.api.nvim_create_augroup("TreesitterInsertOptim", { clear = true }),
        callback = function()
          -- Reduce treesitter update frequency during insert mode
          vim.opt.updatetime = 200
        end,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
        group = vim.api.nvim_create_augroup("TreesitterInsertOptim", { clear = false }),
        callback = function()
          -- Restore normal update frequency
          vim.opt.updatetime = 300
        end,
      })
    end,
  },

  {
    "RRethy/nvim-treesitter-endwise",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "InsertEnter",
    config = function()
      require("nvim-treesitter.configs").setup({
        endwise = {
          enable = true,
        },
      })
    end,
  },

  {
    "windwp/nvim-ts-autotag",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "InsertEnter",
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true,
      },
      per_filetype = {
        ["html"] = { enable_close = false }, -- Example: disable for specific filetypes
      },
    },
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  -- Additional performance-focused treesitter plugins
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      enable = true,
      max_lines = 3, -- Limit context lines for performance
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 1,
      trim_scope = "outer",
      mode = "cursor", -- Show context only around cursor
      separator = nil,
    },
    config = function(_, opts)
      require("treesitter-context").setup(opts)

      -- Keybinding to jump to context
      vim.keymap.set("n", "[c", function()
        require("treesitter-context").go_to_context(vim.v.count1)
      end, { silent = true, desc = "Jump to context" })
    end,
  },
}
