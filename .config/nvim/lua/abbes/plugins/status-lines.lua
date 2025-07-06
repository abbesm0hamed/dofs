return {
  {
    "nvim-lualine/lualine.nvim",
    event = "UIEnter",
    dependencies = {
      "echasnovski/mini.icons",
    },
    external_dependencies = "git",
    opts = {
      sections = {
        lualine_a = {},
        lualine_b = {
          {
            "filename",
            file_status = true,
            newfile_status = false,
            path = 1,
            shorting_target = 40,
            symbols = {
              modified = "[+]",
              readonly = "[-]",
              unnamed = "[No Name]",
              newfile = "[New]",
            },
          },
        },
        lualine_c = {
          {
            "branch",
            icon = { "", align = "left" },
          },
          {
            "diff",
          },
        },
        lualine_x = {},
        lualine_y = {
          {
            "diagnostics",
            symbols = { error = "󰅚 ", warn = " ", info = "󰋽 ", hint = "󰘥 " },
          },
          {
            -- line count
            function()
              return vim.api.nvim_buf_line_count(0) .. " "
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
        theme = "auto", -- Use the current colorscheme's colors
        globalstatus = true,
        always_divide_middle = true,
        component_separators = { left = "", right = "|" },
        section_separators = { left = "", right = "" },
        ignore_focus = {
          "DressingInput",
          "DressingSelect",
          "lspinfo",
          "ccc-ui",
          "TelescopePrompt",
          "checkhealth",
          "lazy",
          "mason",
          "qf",
        },
      },
    },
    extensions = { "trouble" },
  },
}
