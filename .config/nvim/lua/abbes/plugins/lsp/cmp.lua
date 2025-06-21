local sourceIcons = {
  buffer = "󰽙",
  cmdline = "󰘳",
  emoji = "󰞅",
  luasnip = "",
  nvim_lsp = "󰒕",
  path = "",
  emmet_ls = "󰌝",
}

local trigger_text = ";" -- Define trigger_text for snippets

-- Cache frequently used values
local api = vim.api
local fn = vim.fn

return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "moyiz/blink-emoji.nvim",
      "rafamadriz/friendly-snippets",
      {
        "saghen/blink.compat",
        optional = true,
        opts = {},
        version = not vim.g.lazyvim_blink_main and "*",
      },
    },
    version = "*",
    opts = function(_, opts)
      -- Performance: Cache disabled filetypes for faster lookup
      local disabled_filetypes = {
        TelescopePrompt = true,
        minifiles = true,
        snacks_picker_input = true,
      }

      opts.enabled = function()
        return not disabled_filetypes[vim.bo[0].filetype]
      end

      -- Performance optimizations in sources
      opts.sources = vim.tbl_deep_extend("force", opts.sources or {}, {
        -- Reorder sources by frequency of use and performance
        default = { "lsp", "snippets", "buffer", "path", "dadbod", "emoji" },
        providers = {
          lsp = {
            name = "lsp",
            enabled = true,
            module = "blink.cmp.sources.lsp",
            min_keyword_length = 2, -- Increased from 1 to reduce noise
            score_offset = 95, -- Higher priority for LSP
            max_items = 20, -- Limit items for better performance
            -- Performance: Enable async fetching
            async = true,
            -- Performance: Add timeout for slow LSP servers
            timeout_ms = 500,
          },
          snippets = {
            name = "snippets",
            enabled = true,
            max_items = 10, -- Reduced from 15 for better performance
            min_keyword_length = 2, -- Increased to reduce triggering
            module = "blink.cmp.sources.snippets",
            score_offset = 85,
            -- Performance: Optimize snippet detection
            should_show_items = function()
              local col = api.nvim_win_get_cursor(0)[2]
              if col == 0 then
                return false
              end -- Early return for empty line
              local before_cursor = api.nvim_get_current_line():sub(math.max(1, col - 10), col)
              return before_cursor:match(trigger_text .. "%w*$") ~= nil
            end,
            -- Performance: Optimize transform_items with caching
            transform_items = function(_, items)
              if #items == 0 then
                return items
              end -- Early return for empty items

              local line = api.nvim_get_current_line()
              local col = api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local start_pos, end_pos = before_cursor:find(trigger_text .. "[^" .. trigger_text .. "]*$")

              if start_pos then
                local line_num = fn.line(".") - 1
                for _, item in ipairs(items) do
                  if not item.trigger_text_modified then
                    item.trigger_text_modified = true
                    item.textEdit = {
                      newText = item.insertText or item.label,
                      range = {
                        start = { line = line_num, character = start_pos - 1 },
                        ["end"] = { line = line_num, character = end_pos },
                      },
                    }
                  end
                end
              end
              return items
            end,
          },
          buffer = {
            name = "Buffer",
            enabled = true,
            max_items = 5, -- Increased slightly but still limited
            module = "blink.cmp.sources.buffer",
            min_keyword_length = 3, -- Increased to reduce noise
            score_offset = 15,
            -- Performance: Limit buffer scanning
            keyword_pattern = [[\k\+]], -- More specific pattern
            get_bufnrs = function()
              local bufs = {}
              for _, win in ipairs(api.nvim_list_wins()) do
                local buf = api.nvim_win_get_buf(win)
                if api.nvim_buf_is_loaded(buf) and api.nvim_buf_get_option(buf, "buflisted") then
                  table.insert(bufs, buf)
                end
              end
              return bufs
            end,
          },
          path = {
            name = "Path",
            module = "blink.cmp.sources.path",
            score_offset = 25,
            max_items = 8, -- Limit path suggestions
            fallbacks = { "buffer" }, -- Removed snippets from fallbacks
            opts = {
              trailing_slash = false,
              label_trailing_slash = true,
              get_cwd = function(context)
                return fn.expand(("#%d:p:h"):format(context.bufnr))
              end,
              show_hidden_files_by_default = false, -- Changed to false for performance
              -- Performance: Limit directory depth scanning
              max_depth = 3,
            },
          },
          dadbod = {
            name = "Dadbod",
            module = "vim_dadbod_completion.blink",
            min_keyword_length = 2, -- Increased from 1
            score_offset = 80, -- Slightly reduced
            max_items = 15, -- Add limit
            -- Performance: Only enable for SQL filetypes
            enabled = function()
              local ft = vim.bo.filetype
              return ft == "sql" or ft == "mysql" or ft == "plsql"
            end,
          },
          emoji = {
            module = "blink-emoji",
            name = "Emoji",
            score_offset = 10, -- Reduced priority
            max_items = 5, -- Limit emoji suggestions
            opts = {
              insert = true,
            },
            -- Performance: Stricter filetype checking
            should_show_items = function()
              local ft = vim.o.filetype
              return ft == "gitcommit" or ft == "markdown"
            end,
          },
        },
      })

      opts.cmdline = {
        enabled = true,
        -- Performance: Limit cmdline completion
        sources = { "cmdline", "path" },
      }

      opts.completion = {
        accept = {
          -- Performance: Faster auto-insertion
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          border = "none",
          -- Performance: Optimize menu display
          max_height = 15, -- Limit menu height
          scrollbar = false, -- Disable scrollbar for performance
          -- Performance: Faster drawing
          draw = {
            padding = 1,
            gap = 1,
          },
        },
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 200, -- Add delay to reduce flicker
          window = {
            border = "none",
            max_width = 80, -- Limit documentation width
            max_height = 20, -- Limit documentation height
          },
        },
        -- Performance: Optimize completion triggering
        trigger = {
          keyword_length = 2, -- Global minimum keyword length
          signature_help = {
            enabled = true,
            trigger_characters = { "(", "," },
          },
        },
      }

      opts.snippets = {
        preset = "luasnip",
        -- Performance: Optimize snippet expansion
        expand = function(snippet, _)
          require("luasnip").lsp_expand(snippet)
        end,
      }

      -- Performance: Optimize keymaps with faster actions
      opts.keymap = {
        preset = "default",
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" }, -- Changed from S-k
        ["<C-d>"] = { "scroll_documentation_down", "fallback" }, -- Changed from S-j
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        -- Performance: Add quick accept without menu
        ["<C-y>"] = { "accept", "fallback" },
      }

      -- Performance: Add debouncing for better responsiveness
      opts.completion.trigger.show_delay_ms = 50 -- Small delay to debounce rapid typing

      return opts
    end,
    opts_extend = { "sources.default" },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod" },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } },
    },
    keys = {
      { "<leader>d", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      vim.g.db_ui_show_help = 0
      vim.g.db_ui_win_position = "right"
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_use_nvim_notify = 1
      vim.g.db_ui_save_location = fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/db-ui")
      vim.g.db_ui_hide_schemas = { "pg_toast_temp.*" }
      -- Performance: Lazy load DB connections
      vim.g.db_ui_auto_execute_table_helpers = 0
    end,
  },
}
