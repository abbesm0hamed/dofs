return {
  -- Gp.nvim for chat and inline rewrites (using local Ollama)
  {
    "robitx/gp.nvim",
    config = function()
      local conf = {
        chat_user_prefix = "󰭻 User: ",
        chat_assistant_prefix = { "󰚩 AI: ", "[{{agent}}]" },
        providers = {
          ollama = {
            endpoint = "http://localhost:11434/v1/chat/completions",
          },
        },
        agents = {
          {
            name = "OllamaDeepseek",
            chat = true,
            command = true,
            provider = "ollama",
            model = "deepseek-coder",
            system_prompt = "You are a specialized coding assistant. Provide concise and accurate answers.",
          },
        },
      }
      require("gp").setup(conf)
      -- Keybindings (as set before)
      local function keymapOptions(desc)
        return { noremap = true, silent = true, nowait = true, desc = "GPT: " .. desc }
      end
      vim.keymap.set({ "n", "i" }, "<C-g>c", "<cmd>GpChatNew<cr>", keymapOptions("New Chat"))
      vim.keymap.set({ "n", "i" }, "<C-g>t", "<cmd>GpChatToggle<cr>", keymapOptions("Toggle Chat"))
      vim.keymap.set({ "n", "i" }, "<C-g>r", "<cmd>GpRewrite<cr>", keymapOptions("Inline Rewrite"))
    end,
  },

  {
    "Exafunction/codeium.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    event = "BufEnter",
    config = function()
      require("codeium").setup({
        -- Disable cmp source since we're using blink.cmp
        enable_cmp_source = false,
        virtual_text = {
          enabled = true,
          manual = false,
          idle_delay = 75,
          map_keys = true,
          key_bindings = {
            accept = "<A-y>",  -- Changed from Tab to avoid blocking navigation
            next = "<M-]>",
            prev = "<M-[>",
            clear = "<C-x>",
          },
        },
      })
    end,
  },

  -- Avante.nvim for Cursor-like experience (Sidebar + UI integration)
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- Set this to false if you want to use the latest features
    opts = {
      provider = "ollama",
      providers = {
        ollama = {
          __inherited_from = "openai",
          api_key_name = "",
          endpoint = "http://127.0.0.1:11434/v1",
          model = "deepseek-coder",
          always_allow_build = true,
        },
      },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- optional
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_to_mime_type = "image/png",
            insert_mode_after_paste = true,
          },
        },
      },
      {
        -- make sure `Avante` is added as a source for blink.cmp
        "saghen/blink.cmp",
        optional = true,
      },
    },
  },
}
