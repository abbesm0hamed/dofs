-- lualine configuration
local gray_palette = {
  darker = "#232324",
  dark = "#363646",
  soft = "#5b5a5c",
  softer = "#828283",
}
local fg_colors = {
  normal = "#7E9CD8",
  insert = "#a8e6cf",
  visual = "#ffd3b6",
  command = "#D27E99",
  Replace = "#ffb37e",
}
local bg_colors = {
  normal = "#7E9CD8",
  insert = "#a8e6cf",
  visual = "#ffd3b6",
  command = "#D27E99",
  Replace = "#ffb37e",
}
local general_colors = {
  fg = "#000",
  bg = "#2A2A37",
  inactive_bg = "#2c3043",
}

local meovig_lualine = {
  normal = {
    a = { bg = bg_colors.normal, fg = gray_palette.darker },
    b = { fg = fg_colors.normal },
    c = { bg = general_colors.bg, fg = general_colors.fg },
  },
  insert = {
    a = { bg = bg_colors.insert, fg = gray_palette.darker },
    b = { fg = fg_colors.insert },
    c = { bg = general_colors.bg, fg = general_colors.fg },
  },
  visual = {
    a = { bg = bg_colors.visual, fg = gray_palette.darker },
    b = { fg = fg_colors.visual },
    c = { bg = general_colors.bg, fg = general_colors.fg },
  },
  command = {
    a = { bg = bg_colors.command, fg = gray_palette.darker },
    b = { fg = fg_colors.command },
    c = { bg = general_colors.bg, fg = general_colors.fg },
  },
  Replace = {
    a = { bg = bg_colors.Replace, fg = gray_palette.darker },
    b = { fg = fg_colors.Replace },
    c = { bg = general_colors.bg, fg = general_colors.fg },
  },
  inactive = {
    a = { bg = general_colors.bg, fg = general_colors.semilightgray },
    b = { bg = general_colors.bg, fg = general_colors.semilightgray },
    c = { bg = general_colors.bg, fg = general_colors.semilightgray },
  },
}
local lualineConfig = {
  sections = {
    lualine_a = {
      -- {
      --   "filetype",
      --   color = nil,
      --   colored = false,  -- Displays filetype icon in color if set to true
      --   icon_only = true, -- Display only an icon for filetype
      --   icon = { "X", align = "right" },
      --   -- Icon string ^ in table is ignored in filetype component
      -- },
    },
    lualine_b = {
      {
        "filename",
        color = { bg = gray_palette.darker },
        file_status = true, -- Displays file status (readonly status, modified status)
        newfile_status = false, -- Display new file status (new file means no write after created)
        path = 1, -- 0: Just the filename
        -- 1: Relative path
        -- 2: Absolute path
        -- 3: Absolute path, with tilde as the home directory
        -- 4: Filename and parent dir, with tilde as the home directory

        shorting_target = 40, -- Shortens path to leave 40 spaces in the window
        -- for other components. (terrible name, any suggestions?)
        symbols = {
          modified = "[+]", -- Text to show when the file is modified.
          readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
          unnamed = "[No Name]", -- Text to show for unnamed buffers.
          newfile = "[New]", -- Text to show for newly created file before first write
        },
      },
    },
    lualine_c = {
      {
        "branch",
        icon = { "", align = "left" },
        color = { bg = gray_palette.dark },
      },
      {
        "diff",
        color = { bg = gray_palette.dark },
      },
    },
    lualine_x = {},
    lualine_y = {
      {
        "diagnostics",
        color = { bg = gray_palette.dark },
        symbols = { error = "󰅚 ", warn = " ", info = "󰋽 ", hint = "󰘥 " },
      },
      {
        -- line count
        color = { bg = gray_palette.darker },
        function()
          return vim.api.nvim_buf_line_count(0) .. " "
        end,
        cond = function()
          return vim.bo.buftype == ""
        end,
      },
    },
    lualine_z = {
      {
        "selectioncount",
        fmt = function(str)
          return str ~= "" and "󰒆 " .. str or ""
        end,
      },
      {
        "location",
      },
    },
  },
  options = {
    theme = meovig_lualine, -- make this nil to use currently set colorscheme config
    globalstatus = true,
    always_divide_middle = true,
    -- nerdfont-powerline icons prefix: ple-
    component_separators = { left = "", right = "|" },
    section_separators = { left = "", right = "" },
    -- stylua: ignore
    ignore_focus = {
      "DressingInput", "DressingSelect", "lspinfo", "ccc-ui", "TelescopePrompt",
      "checkhealth", "lazy", "mason", "qf",
    },
  },
}

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "UIEnter",
    -- enabled = false,
    dependencies = {
      "echasnovski/mini.icons",
    },
    external_dependencies = "git",
    opts = lualineConfig,
    extensions = { "toggleterm", "trouble" },
  },
}
