return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    build = ":CatppuccinCompile",
    opts = {
      transparent_background = false,
      flavour = "mocha",
      styles = {
        comments = { "italic" },
        keywords = { "italic" },
        functions = {},
        strings = {},
        variables = {},
      },
      color_overrides = {
        mocha = {
          base = "#0D0E11",
          mantle = "#06060b",
          crust = "#030308",
          surface0 = "#0e0e16",
          surface1 = "#14141e",
          surface2 = "#1c1c28",
          overlay0 = "#383850",
          overlay1 = "#5a5a78",
          overlay2 = "#7070a0",
          subtext0 = "#9090aa",
          subtext1 = "#b0b0c8",
          text = "#dcdce8",

          blue = "#88b4e8", -- keywords, types
          teal = "#6dd4bc", -- functions
          peach = "#e8a87c", -- numbers, constants
          green = "#d4c46a", -- strings → warm golden yellow
          red = "#e88a97",
          yellow = "#e8d080", -- pastel lemon (used for variables/params)

          lavender = "#88b4e8",
          mauve = "#88b4e8",
          pink = "#88b4e8",
          sky = "#88b4e8",
          sapphire = "#88b4e8",
          maroon = "#e88a97",
          flamingo = "#e88a97",
          rosewater = "#c8a8e8", -- variables → soft purple
        },
      },
      custom_highlights = function(c)
        return {
          -- Backgrounds
          Normal = { bg = c.base, fg = c.text },
          NormalNC = { bg = c.base },
          NormalFloat = { bg = c.mantle },
          FloatBorder = { fg = c.surface2, bg = c.mantle },
          WinSeparator = { fg = c.surface1 },

          -- Cursor
          CursorLine = { bg = c.surface0 },
          CursorLineNr = { fg = c.blue, bold = true },
          LineNr = { fg = c.overlay1 },

          -- Selection & search
          Visual = { bg = c.surface2 },
          Search = { bg = c.surface2, fg = c.text, bold = true },
          IncSearch = { bg = c.blue, fg = c.base, bold = true },

          -- Comments
          Comment = { fg = c.subtext0, italic = true },

          -- Popups
          Pmenu = { bg = c.mantle },
          PmenuSel = { bg = c.surface1, bold = true },
          PmenuThumb = { bg = c.surface2 },

          -- Statusline / tabs
          StatusLine = { bg = c.mantle, fg = c.subtext0 },
          TabLineFill = { bg = c.crust },
          TabLine = { bg = c.mantle, fg = c.overlay1 },
          TabLineSel = { bg = c.surface0, fg = c.text, bold = true },

          -- Gutter
          SignColumn = { bg = c.base },
          FoldColumn = { bg = c.base },

          -- THE ONLY 4 SYNTAX COLORS
          Keyword = { fg = c.blue, italic = true },
          Statement = { fg = c.blue, italic = true },
          Function = { fg = c.teal },
          String = { fg = c.green },
          Number = { fg = c.peach },
          Boolean = { fg = c.peach },
          Constant = { fg = c.peach },
          Type = { fg = c.blue },
          PreProc = { fg = c.blue },
          Special = { fg = c.text },
          Operator = { fg = c.text },
          Identifier = { fg = c.text },

          -- Treesitter — same 4 colors, nothing extra
          ["@keyword"] = { fg = c.blue, italic = true },
          ["@keyword.return"] = { fg = c.blue, italic = true },
          ["@function"] = { fg = c.teal },
          ["@function.builtin"] = { fg = c.teal },
          ["@method"] = { fg = c.teal },
          ["@string"] = { fg = c.green },
          ["@number"] = { fg = c.peach },
          ["@boolean"] = { fg = c.peach },
          ["@constant"] = { fg = c.peach },
          ["@constant.builtin"] = { fg = c.peach },
          ["@type"] = { fg = c.blue },
          ["@type.builtin"] = { fg = c.blue },
          ["@tag"] = { fg = c.blue },
          ["@tag.attribute"] = { fg = c.subtext1 },
          ["@tag.delimiter"] = { fg = c.overlay1 },
          ["@parameter"] = { fg = c.text },
          ["@operator"] = { fg = c.text },
          ["@punctuation.bracket"] = { fg = c.overlay2 },
          ["@punctuation.delimiter"] = { fg = c.overlay1 },
          ["@comment"] = { fg = c.subtext0, italic = true },
          ["@attribute"] = { fg = c.blue },
          ["@namespace"] = { fg = c.text },
          ["@constructor"] = { fg = c.text },
          ["@variable"] = { fg = c.rosewater }, -- or pick any accent
          ["@variable.builtin"] = { fg = c.rosewater, italic = true },
          ["@variable.parameter"] = { fg = c.rosewater },
          ["@field"] = { fg = c.rosewater },
          ["@property"] = { fg = c.rosewater },

          -- Diagnostics
          DiagnosticError = { fg = c.red },
          DiagnosticWarn = { fg = c.yellow },
          DiagnosticInfo = { fg = c.blue },
          DiagnosticHint = { fg = c.teal },
          DiagnosticVirtualTextError = { fg = c.red, bg = c.surface0, italic = true },
          DiagnosticVirtualTextWarn = { fg = c.yellow, bg = c.surface0, italic = true },
          DiagnosticUnderlineError = { undercurl = true, sp = c.red },
          DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
        }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd("colorscheme catppuccin")
    end,
  },
}
