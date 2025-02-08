return {
  -- Configure LazyVim to load theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },
  -- best
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    event = "VimEnter",
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        compile = false, -- enable compiling the colorscheme
        undercurl = true, -- enable undercurls
        commentStyle = { italic = true },
        functionStyle = { italic = false, bold = false },
        keywordStyle = { italic = false },
        statementStyle = { bold = true },
        typeStyle = {},
        transparent = false, -- do not set background color
        dimInactive = false, -- dim inactive window `:h hl-NormalNC`
        terminalColors = true, -- define vim.g.terminal_color_{0,17}
        colors = {
          -- add/modify theme and palette colors
          palette = {},
          theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
        },
        overrides = function(colors) -- add/modify highlights
          return {}
        end,
        theme = "wave", -- Load "wave" theme when 'background' option is not set
        background = { -- map the value of 'background' option to a theme
          dark = "wave", -- try "dragon" !
          light = "lotus",
        },
      })

      vim.cmd("colorscheme kanagawa")
    end,
  },
  --
  --new
  -- {
  --   "dgox16/oldworld.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     variant = "oled",
  --   },
  -- },
  --
  -- {
  --   "ficcdaf/ashen.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   -- configuration is optional!
  --   init = function()
  --     vim.cmd("colorscheme ashen")
  --   end
  -- },
  --
  -- {
  --   "wnkz/monoglow.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {},
  --   config = function()
  --     vim.cmd([[colorscheme monoglow]])
  --   end,
  -- },
  --
  -- {
  --   "nuvic/flexoki-nvim",
  --   name = "flexoki",
  --   config = function()
  --     require("flexoki").setup({
  --       variant = "auto", -- auto, moon, or dawn
  --       dim_inactive_windows = false,
  --       extend_background_behind_borders = true,
  --
  --       enable = {
  --         terminal = true,
  --         legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
  --         migrations = true,        -- Handle deprecated options automatically
  --       },
  --
  --       styles = {
  --         bold = true,
  --         italic = false,
  --         transparency = false,
  --       },
  --
  --       groups = {
  --         border = "muted",
  --         link = "purple_two",
  --         panel = "surface",
  --
  --         error = "red_one",
  --         hint = "purple_one",
  --         info = "cyan_one",
  --         ok = "green_one",
  --         warn = "orange_one",
  --         note = "blue_one",
  --         todo = "magenta_one",
  --
  --         git_add = "green_one",
  --         git_change = "yellow_one",
  --         git_delete = "red_one",
  --         git_dirty = "yellow_one",
  --         git_ignore = "muted",
  --         git_merge = "purple_one",
  --         git_rename = "blue_one",
  --         git_stage = "purple_one",
  --         git_text = "magenta_one",
  --         git_untracked = "subtle",
  --
  --         h1 = "purple_two",
  --         h2 = "cyan_two",
  --         h3 = "magenta_two",
  --         h4 = "orange_two",
  --         h5 = "blue_two",
  --         h6 = "cyan_two",
  --       },
  --
  --       palette = {
  --         -- Override the builtin palette per variant
  --         -- moon = {
  --         --     base = '#100f0f',
  --         --     overlay = '#1c1b1a',
  --         -- },
  --       },
  --
  --       highlight_groups = {
  --         -- Comment = { fg = "subtle" },
  --         -- VertSplit = { fg = "muted", bg = "muted" },
  --       },
  --
  --       before_highlight = function(group, highlight, palette)
  --         -- Disable all undercurls
  --         -- if highlight.undercurl then
  --         --     highlight.undercurl = false
  --         -- end
  --         --
  --         -- Change palette colour
  --         -- if highlight.fg == palette.blue_two then
  --         --     highlight.fg = palette.cyan_two
  --         -- end
  --       end,
  --     })
  --
  --     -- vim.cmd("colorscheme flexoki")
  --     vim.cmd("colorscheme flexoki-moon")
  --     -- vim.cmd("colorscheme flexoki-dawn")
  --   end,
  -- },
  --
  -- {
  --   "wtfox/jellybeans.nvim",
  --   priority = 1000,
  --   config = function()
  --     require("jellybeans").setup()
  --     vim.cmd.colorscheme("jellybeans")
  --   end,
  -- },
  --
  -- lackluster
  -- {
  --   "slugbyte/lackluster.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   init = function()
  --     -- vim.cmd.colorscheme("lackluster")
  --     vim.cmd.colorscheme("lackluster-hack") -- my favorite
  --     -- vim.cmd.colorscheme("lackluster-mint")
  --   end,
  --   config = function()
  --     local lackluster = require('lackluster')
  --     lackluster.setup({
  --       -- tweak_color allows you to overwrite the default colors in the lackluster theme
  --       tweak_color = {
  --         -- you can set a value to a custom hexcode like' #aaaa77' (hashtag required)
  --         -- or if the value is 'default' or nil it will use lackluster's default color
  --         -- lack = "#aaaa77",
  --         lack = "default",
  --         luster = "default",
  --         orange = "default",
  --         yellow = "default",
  --         green = "default",
  --         blue = "default",
  --         red = "default",
  --         -- WARN: Watchout! messing with grays is probs a bad idea, its very easy to shoot yourself in the foot!
  --         -- black = "default",
  --         -- gray1 = "default",
  --         -- gray2 = "default",
  --         -- gray3 = "default",
  --         -- gray4 = "default",
  --         -- gray5 = "default",
  --         -- gray6 = "default",
  --         -- gray7 = "default",
  --         -- gray8 = "default",
  --         -- gray9 = "default",
  --
  --       },
  --     })
  --   end,
  -- }
  --
  -- flexoki
  -- {
  --   "kepano/flexoki-neovim",
  --   lazy = true,
  --   event = "VimEnter",
  --   priority = 1000,
  --   config = function()
  --     require("lazy").setup({
  --       { 'kepano/flexoki-neovim', name = 'flexoki' }
  --     })
  --     vim.cmd('colorscheme flexoki-dark')
  --   end,
  -- },
  -- {
  --   "CosecSecCot/midnight-desert.nvim",
  --   dependencies = {
  --     "rktjmp/lush.nvim",
  --   },
  --   config = function()
  --     vim.cmd("colorscheme midnight-desert")
  --   end,
  --   -- no setup function required
  -- },
  -- {
  --   "yorumicolors/yorumi.nvim",
  --   event = "VimEnter",
  --   name = "yorumi",
  --   priority = 1000,
  --   config = function()
  --     vim.cmd("colorscheme yorumi")
  --   end,
  -- },
  -- top 1
  -- {
  --   "bluz71/vim-moonfly-colors",
  --   event = "VimEnter",
  --   name = "moonfly",
  --   priority = 1000,
  --   config = function()
  --     -- Moonfly configuration
  --     vim.g.moonflyCursorColor = true
  --     vim.g.moonflyItalics = true
  --     vim.g.moonflyNormalFloat = true
  --     vim.g.moonflyTerminalColors = true
  --     vim.g.moonflyVirtualTextColor = true
  --     vim.g.moonflyUndercurls = true
  --     vim.g.moonflyVertSplits = true
  --
  --     -- Reduce used colors
  --     vim.g.moonflyWinSeparator = 1
  --
  --     -- Set colorscheme
  --     vim.cmd.colorscheme("moonfly")
  --
  --     -- Override function and search highlights to include italics
  --     vim.api.nvim_set_hl(0, "Function", { italic = true })
  --     vim.api.nvim_set_hl(0, "Search", { italic = true })
  --   end,
  -- },
  -- {
  --   "bluz71/vim-nightfly-colors",
  --   name = "nightfly",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd.colorscheme("nightfly")
  --   end,
  -- },
  -- top 2
  -- vimbones = light
  -- neobones = dark
  -- {
  --   "mcchrish/zenbones.nvim",
  --   priority = 1000,
  --   lazy = false,
  --   dependencies = {
  --     "rktjmp/lush.nvim"
  --   },
  --   config = function()
  --     vim.cmd.colorscheme("zenbones")
  --   end,
  -- },
  -- {
  --   "nyoom-engineering/oxocarbon.nvim",
  --   lazy = false,          -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000,       -- make sure to load this before all the other start plugins
  --   opts = {
  --     background = "dark", -- dark or light
  --   },
  --   config = function()
  --     -- load the colorscheme here
  --     vim.cmd.colorscheme("oxocarbon")
  --     vim.opt.background = "dark" -- light | dark
  --   end,
  -- },
  -- top 3
  -- {
  --   "blazkowolf/gruber-darker.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     bold = true,
  --     invert = {
  --       signs = false,
  --       tabline = false,
  --       visual = false,
  --     },
  --     italic = {
  --       strings = true,
  --       comments = true,
  --       operators = false,
  --       folds = true,
  --     },
  --     undercurl = true,
  --     underline = true,
  --   },
  --   config = function()
  --     require("gruber-darker").setup({})
  --   end,
  -- },
  -- top 4
  -- {
  --   "kevinm6/kurayami.nvim",
  --   event = "VimEnter", -- load plugin on VimEnter or
  --   lazy = false,       --   don't lazy load plugin
  --   priority = 1000,
  --   config = function()
  --     vim.cmd.colorscheme("kurayami") -- this is enough to initialize and load plugin
  --   end,
  --
  --   ---Use this config to override some highlights
  --   -- config = function(_, opts)
  --   ---override highlights passing table
  --   ---@usage
  --   -- opts.override = {
  --   --  Number = { fg = "#015a60" }
  --   -- }
  --   -- require("kurayami").setup(opts)
  --   -- end
  -- },
  -- top 5
  -- {
  --   "Shatur/neovim-ayu",
  --   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   opts = {
  --     theme = "ayu",
  --   },
  --   config = function()
  --     vim.cmd.colorscheme("ayu")
  --   end,
  -- },
  -- {
  --   "kvrohit/rasmus.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd("colorscheme rasmus")
  --   end,
  -- },
  -- github
  -- {
  --   'projekt0n/github-nvim-theme',
  --   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     require('github-theme').setup({
  --       -- ...
  --     })
  --
  --     vim.cmd('colorscheme github_dark_default')
  --   end,
  -- }
  -- {
  --   "Mofiqul/adwaita.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.g.adwaita_darker = true              -- for darker version
  --     vim.g.adwaita_disable_cursorline = false -- to disable cursorline
  --     vim.g.adwaita_transparent = false        -- makes the background transparent
  --     vim.cmd('colorscheme adwaita')
  --   end
  -- },
  -- --
  -- this also has one of the best light colorschemes
  -- {
  --   "miikanissi/modus-themes.nvim",
  --   priority = 1000,
  --   config = function()
  --     require("modus-themes").setup({
  --       -- Theme comes in two styles `modus_operandi` and `modus_vivendi`
  --       -- `auto` will automatically set style based on background set with vim.o.background
  --       style = "auto",
  --       variant = "default",  -- Theme comes in four variants `default`, `tinted`, `deuteranopia`, and `tritanopia`
  --       transparent = false,  -- Transparent background (as supported by the terminal)
  --       dim_inactive = false, -- "non-current" windows are dimmed
  --       styles = {
  --         -- Style to be applied to different syntax groups
  --         -- Value is any valid attr-list value for `:help nvim_set_hl`
  --         comments = { italic = true },
  --         keywords = { italic = true },
  --         functions = {},
  --         variables = {},
  --       },
  --
  --       --- You can override specific color groups to use other groups or a hex color
  --       --- function will be called with a ColorScheme table
  --       ---@param colors ColorScheme
  --       on_colors = function(colors) end,
  --
  --       --- You can override specific highlights to use other groups or a hex color
  --       --- function will be called with a Highlights and ColorScheme table
  --       ---@param highlights Highlights
  --       ---@param colors ColorScheme
  --       on_highlights = function(highlights, colors) end,
  --     })
  --   end,
  -- },
  -- {
  --   "Abstract-IDE/Abstract-cs",
  --   priority = 1000,
  --   lazy = false,
  --   config = function()
  --     -- load the colorscheme here
  --     vim.cmd([[colorscheme abscs]])
  --   end,
  -- },
  -- {
  --   "embark-theme/vim",
  --   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     vim.cmd.colorscheme("embark")
  --   end,
  -- },
  -- {
  --   "rose-pine/neovim",
  --   lazy = false,
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     -- load the colorscheme here
  --     vim.cmd([[colorscheme rose-pine]])
  --   end,
  -- },
  --
  -- {
  --   "oxfist/night-owl.nvim",
  --   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     -- load the colorscheme here
  --     vim.cmd.colorscheme("night-owl")
  --   end,
  -- },
  -- tokyo
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {},
  --   config=function ()
  --     vim.cmd[[colorscheme tokyonight-moon]]
  --   end,
  -- },
  -- {
  --   "tiagovla/tokyodark.nvim",
  --   opts = {
  --     transparent_background = false,    -- set background to transparent
  --     gamma = 1.00,                      -- adjust the brightness of the theme
  --     styles = {
  --       comments = { italic = true },    -- style for comments
  --       keywords = { italic = true },    -- style for keywords
  --       identifiers = { italic = true }, -- style for identifiers
  --       functions = {},                  -- style for functions
  --       variables = {},                  -- style for variables
  --     },
  --     custom_highlights = function(hl, p)
  --       return {
  --           ["LspInlayHint"] = { bg = "#1C1C2A", fg = "#9AA0A7" },
  --           ["@module"] = { link = "TSType" },
  --           ["@property"] = { link = "Identifier" },
  --           ["@variable"] = { fg = "#Afa8ea" },
  --           ["@lsp.type.variable"] = { fg = "#Afa8ea" },
  --           ["FloatTitle"] = { link = "Blue" },
  --           ["TelescopeBorder"] = { link = "TSType" },
  --           ["TelescopePreviewBorder"] = { fg = "#4A5057" },
  --           ["TelescopePreviewTitle"] = { link = "Blue" },
  --           ["TelescopePromptBorder"] = { fg = "#4A5057" },
  --           ["TelescopePromptTitle"] = { link = "Blue" },
  --           ["TelescopeResultsBorder"] = { fg = "#4A5057" },
  --           ["TelescopeResultsTitle"] = { link = "Blue" },
  --           ["CmpItemKindCopilot"] = { fg = "#6CC644" },
  --           ["NoiceLspProgressSpinner"] = { bg = "#1C1C2A" },
  --           ["NoiceLspProgressClient"] = { bg = "#1C1C2A" },
  --           ["NoiceLspProgressTitle"] = { bg = "#1C1C2A" },
  --           ["NoiceMini"] = { bg = "#1C1C2A" },
  --           ["NoiceCmdlineIconSearch"] = { link = "Blue" },
  --       }
  --     end,
  --     custom_palette = {} or function(palette)
  --       return {}
  --     end, -- extend palette
  --     terminal_colors = true,
  --   },
  --   config = function(_, opts)
  --     require("tokyodark").setup(opts) -- calling setup is optional
  --     vim.cmd([[colorscheme tokyodark]])
  --   end,
  -- },
  -- {
  --   "metalelf0/jellybeans-nvim",
  --   dependencies = {
  --     "rktjmp/lush.nvim",
  --   },
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd.colorscheme("jellybeans-nvim")
  --   end,
  -- },
  -- {
  --   "loctvl842/monokai-pro.nvim",
  --   dependencies = {
  --     "rktjmp/lush.nvim",
  --   },
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("monokai-pro").setup({
  --       transparent_background = false,
  --       terminal_colors = true,
  --       devicons = true, -- highlight the icons of `nvim-web-devicons`
  --       styles = {
  --         comment = { italic = true },
  --         keyword = { italic = true },       -- any other keyword
  --         type = { italic = true },          -- (preferred) int, long, char, etc
  --         storageclass = { italic = true },  -- static, register, volatile, etc
  --         structure = { italic = true },     -- struct, union, enum, etc
  --         parameter = { italic = true },     -- parameter pass in function
  --         annotation = { italic = true },
  --         tag_attribute = { italic = true }, -- attribute of tag in reactjs
  --       },
  --       filter = "pro",                      -- classic | octagon | pro | machine | ristretto | spectrum
  --       -- Enable this will disable filter option
  --       day_night = {
  --         enable = false,            -- turn off by default
  --         day_filter = "pro",        -- classic | octagon | pro | machine | ristretto | spectrum
  --         night_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
  --       },
  --       inc_search = "background",   -- underline | background
  --       background_clear = {
  --         -- "float_win",
  --         "toggleterm",
  --         "telescope",
  --         -- "which-key",
  --         "renamer",
  --         "notify",
  --         -- "nvim-tree",
  --         -- "neo-tree",
  --         -- "bufferline", -- better used if background of `neo-tree` or `nvim-tree` is cleared
  --       }, -- "float_win", "toggleterm", "telescope", "which-key", "renamer", "neo-tree", "nvim-tree", "bufferline"
  --       plugins = {
  --         bufferline = {
  --           underline_selected = false,
  --           underline_visible = false,
  --         },
  --         indent_blankline = {
  --           context_highlight = "default", -- default | pro
  --           context_start_underline = false,
  --         },
  --       },
  --     })
  --   end,
  -- },
  --
  -- no-clown-fiesta
  -- {
  --   'aktersnurra/no-clown-fiesta.nvim',
  --   priority = 1000, -- Load colorscheme before other plugins
  --   lazy = false,    -- Load during startup
  --   config = function()
  --     require('no-clown-fiesta').setup({
  --       -- Default config
  --       transparent = false, -- Enable transparent background
  --       styles = {
  --         -- Styling choices for syntax elements
  --         comments = {},     -- Style for comments
  --         keywords = {},     -- Style for keywords
  --         functions = {},    -- Style for functions
  --         variables = {},    -- Style for variables
  --         type = {},         -- Style for type annotations
  --         virtual_text = {}, -- Style for virtual text
  --       },
  --       -- Enable/disable specific features
  --       features = {
  --         syntax = true,          -- Enable basic syntax highlighting
  --         treesitter = true,      -- Enable TreeSitter support
  --         semantic_tokens = true, -- Enable LSP semantic tokens
  --         diagnostic = true,      -- Style diagnostic messages
  --       },
  --       -- Optional: Override specific highlight groups
  --       highlights = {
  --         -- Example: override a highlight group
  --         -- Comment = { fg = "#7C7C7C" }
  --       },
  --     })
  --
  --     -- Set the colorscheme
  --     vim.cmd.colorscheme('no-clown-fiesta')
  --   end,
  -- },
  --
  -- gruvbox dark hard
  -- {
  --   "wincent/base16-nvim",
  --   lazy = false,    -- load at start
  --   priority = 1000, -- load first
  --   config = function()
  --     vim.cmd([[colorscheme base16-gruvbox-dark-hard]])
  --     vim.o.background = 'dark'
  --     -- XXX: hi Normal ctermbg=NONE
  --     -- Make comments more prominent -- they are important.
  --     local bools = vim.api.nvim_get_hl(0, { name = 'Boolean' })
  --     vim.api.nvim_set_hl(0, 'Comment', bools)
  --     -- Make it clearly visible which argument we're at.
  --     local marked = vim.api.nvim_get_hl(0, { name = 'PMenu' })
  --     vim.api.nvim_set_hl(0, 'LspSignatureActiveParameter',
  --       { fg = marked.fg, bg = marked.bg, ctermfg = marked.ctermfg, ctermbg = marked.ctermbg, bold = true })
  --     -- XXX
  --     -- Would be nice to customize the highlighting of warnings and the like to make
  --     -- them less glaring. But alas
  --     -- https://github.com/nvim-lua/lsp_extensions.nvim/issues/21
  --     -- call Base16hi("CocHintSign", g:base16_gui03, "", g:base16_cterm03, "", "", "")
  --   end
  -- },
  --
  -- {
  --   "matsuuu/pinkmare",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd("colorscheme pinkmare")
  --   end,
  -- },
}
