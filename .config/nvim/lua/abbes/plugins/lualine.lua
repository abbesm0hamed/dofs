-- lualine configuration
-- local gray_palette = {
--   darker = "#232324",
--   dark = "#403f41",
--   soft = "#5b5a5c",
--   softer = "#828283",
-- }
-- local fg_colors = {
--   normal = "#87af87",
--   insert = "#cad3f5",
--   visual = "#a8e6cf",
--   command = "#ffd3b6",
--   Replace = "#ffb37e",
-- }
-- local bg_colors = {
--   normal = "#87af87",
--   insert = "#cad3f5",
--   visual = "#a8e6cf",
--   command = "#ffe2b6",
--   Replace = "#ffb37e",
-- }
-- local general_colors = {
--   fg = "#000",
--   bg = "#303030",
--   inactive_bg = "#2c3043",
-- }
--
-- local meovig_lualine = {
--   normal = {
--     a = { bg = bg_colors.normal, fg = gray_palette.darker },
--     b = { fg = fg_colors.normal },
--     c = { bg = general_colors.bg, fg = general_colors.fg },
--   },
--   insert = {
--     a = { bg = bg_colors.insert, fg = gray_palette.darker },
--     b = { fg = fg_colors.insert },
--     c = { bg = general_colors.bg, fg = general_colors.fg },
--   },
--   visual = {
--     a = { bg = bg_colors.visual, fg = gray_palette.darker },
--     b = { fg = fg_colors.visual },
--     c = { bg = general_colors.bg, fg = general_colors.fg },
--   },
--   command = {
--     a = { bg = bg_colors.command, fg = gray_palette.darker },
--     b = { fg = fg_colors.command },
--     c = { bg = general_colors.bg, fg = general_colors.fg },
--   },
--   Replace = {
--     a = { bg = bg_colors.Replace, fg = gray_palette.darker },
--     b = { fg = fg_colors.Replace },
--     c = { bg = general_colors.bg, fg = general_colors.fg },
--   },
--   inactive = {
--     a = { bg = general_colors.bg, fg = general_colors.semilightgray },
--     b = { bg = general_colors.bg, fg = general_colors.semilightgray },
--     c = { bg = general_colors.bg, fg = general_colors.semilightgray },
--   },
-- }
-- local lualineConfig = {
--   sections = {
--     lualine_a = {
--       -- {
--       --   "filetype",
--       --   color = nil,
--       --   colored = false,  -- Displays filetype icon in color if set to true
--       --   icon_only = true, -- Display only an icon for filetype
--       --   icon = { "X", align = "right" },
--       --   -- Icon string ^ in table is ignored in filetype component
--       -- },
--     },
--     lualine_b = {
--       {
--         "filename",
--         color = { bg = gray_palette.darker },
--         file_status = true,     -- Displays file status (readonly status, modified status)
--         newfile_status = false, -- Display new file status (new file means no write after created)
--         path = 4,               -- 0: Just the filename
--         -- 1: Relative path
--         -- 2: Absolute path
--         -- 3: Absolute path, with tilde as the home directory
--         -- 4: Filename and parent dir, with tilde as the home directory
--
--         shorting_target = 40, -- Shortens path to leave 40 spaces in the window
--         -- for other components. (terrible name, any suggestions?)
--         symbols = {
--           modified = "[+]",      -- Text to show when the file is modified.
--           readonly = "[-]",      -- Text to show when the file is non-modifiable or readonly.
--           unnamed = "[No Name]", -- Text to show for unnamed buffers.
--           newfile = "[New]",     -- Text to show for newly created file before first write
--         },
--       },
--     },
--     lualine_c = {
--       {
--         "branch",
--         icon = { "", align = "left" },
--         color = { bg = gray_palette.dark },
--       },
--       {
--         "diff",
--         color = { bg = gray_palette.dark },
--       },
--     },
--     lualine_x = {},
--     lualine_y = {
--       {
--         "diagnostics",
--         color = { bg = gray_palette.dark },
--         symbols = { error = "󰅚 ", warn = " ", info = "󰋽 ", hint = "󰘥 " },
--       },
--       {
--         -- line count
--         color = { bg = gray_palette.darker },
--         function()
--           return vim.api.nvim_buf_line_count(0) .. " "
--         end,
--         cond = function()
--           return vim.bo.buftype == ""
--         end,
--       },
--     },
--     lualine_z = {
--       {
--         "selectioncount",
--         fmt = function(str)
--           return str ~= "" and "礪" .. str or ""
--         end,
--       },
--       {
--         "location",
--       },
--     },
--   },
--   options = {
--     theme = meovig_lualine, -- make this nil to use currently set colorscheme config
--     globalstatus = true,
--     always_divide_middle = true,
--     -- nerdfont-powerline icons prefix: ple-
--     component_separators = { left = "", right = "|" },
--     section_separators = { left = "", right = "" },
--     -- stylua: ignore
--     ignore_focus = {
--       "DressingInput", "DressingSelect", "lspinfo", "ccc-ui", "TelescopePrompt",
--       "checkhealth", "lazy", "mason", "qf",
--     },
--   },
-- }

-- lightline configuration

return {
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   event = "UIEnter",
  --   dependencies = "nvim-tree/nvim-web-devicons",
  --   external_dependencies = "git",
  --   opts = lualineConfig,
  --   extensions = { "toggleterm", "trouble" },
  -- },
  -- {
  --   "itchyny/lightline.vim",
  --   event = "VimEnter",
  --   config = function()
  --     -- Color palette
  --     local gray_palette = {
  --       darker = "#232324",
  --       dark = "#403f41",
  --       soft = "#5b5a5c",
  --       softer = "#828283",
  --     }
  --
  --     local fg_colors = {
  --       normal = "#87af87",
  --       insert = "#cad3f5",
  --       visual = "#a8e6cf",
  --       command = "#ffd3b6",
  --       Replace = "#ffb37e",
  --     }
  --
  --     local bg_colors = {
  --       normal = "#87af87",
  --       insert = "#cad3f5",
  --       visual = "#a8e6cf",
  --       command = "#ffe2b6",
  --       Replace = "#ffb37e",
  --     }
  --
  --     local general_colors = {
  --       fg = "#000",
  --       bg = "#303030",
  --       inactive_bg = "#2c3043",
  --     }
  --
  --     -- Define the color scheme in Lua
  --     local p = {
  --       normal = {},
  --       insert = {},
  --       visual = {},
  --       command = {},
  --       Replace = {},
  --       inactive = {},
  --     }
  --
  --     p.normal.left = { { gray_palette.darker, bg_colors.normal }, { fg_colors.normal, general_colors.bg } }
  --     p.normal.middle = { { general_colors.fg, general_colors.bg } }
  --     p.normal.right = { { gray_palette.darker, bg_colors.normal }, { fg_colors.normal, gray_palette.dark } }
  --
  --     p.insert.left = { { gray_palette.darker, bg_colors.insert }, { fg_colors.insert, general_colors.bg } }
  --     p.insert.middle = { { general_colors.fg, general_colors.bg } }
  --     p.insert.right = { { gray_palette.darker, bg_colors.insert }, { fg_colors.insert, gray_palette.dark } }
  --
  --     p.visual.left = { { gray_palette.darker, bg_colors.visual }, { fg_colors.visual, general_colors.bg } }
  --     p.visual.middle = { { general_colors.fg, general_colors.bg } }
  --     p.visual.right = { { gray_palette.darker, bg_colors.visual }, { fg_colors.visual, gray_palette.dark } }
  --
  --     p.command.left = { { gray_palette.darker, bg_colors.command }, { fg_colors.command, general_colors.bg } }
  --     p.command.middle = { { general_colors.fg, general_colors.bg } }
  --     p.command.right = { { gray_palette.darker, bg_colors.command }, { fg_colors.command, gray_palette.dark } }
  --
  --     p.Replace.left = { { gray_palette.darker, bg_colors.Replace }, { fg_colors.Replace, general_colors.bg } }
  --     p.Replace.middle = { { general_colors.fg, general_colors.bg } }
  --     p.Replace.right = { { gray_palette.darker, bg_colors.Replace }, { fg_colors.Replace, gray_palette.dark } }
  --
  --     p.inactive.left = { { general_colors.bg, general_colors.bg }, { general_colors.bg, general_colors.bg } }
  --     p.inactive.middle = { { general_colors.bg, general_colors.bg } }
  --     p.inactive.right = { { general_colors.bg, general_colors.bg }, { general_colors.bg, general_colors.bg } }
  --
  --     -- Convert Lua table to Vim dictionary string
  --     local function lua_table_to_vim_dict(t)
  --       local result = "{"
  --       for k, v in pairs(t) do
  --         if type(v) == "table" then
  --           result = result .. k .. ": " .. lua_table_to_vim_dict(v) .. ","
  --         else
  --           result = result .. k .. ": '" .. v .. "',"
  --         end
  --       end
  --       return result .. "}"
  --     end
  --
  --     -- Set the color scheme
  --     vim.cmd("let g:lightline#colorscheme#meovig_lightline#palette = lightline#colorscheme#flatten(" ..
  --     lua_table_to_vim_dict(p) .. ")")
  --
  --     -- Lightline configuration
  --     vim.g.lightline = {
  --       colorscheme = 'meovig_lightline',
  --       active = {
  --         left = {
  --           {},
  --           {
  --             'filename',
  --           },
  --           {
  --             'branch',
  --             'diff',
  --           },
  --         },
  --         right = {
  --           {
  --             'diagnostics',
  --           },
  --           {
  --             'linecount',
  --           },
  --           {
  --             'selectioncount',
  --             'location',
  --           },
  --         },
  --       },
  --       inactive = {
  --         left = { { 'filename' } },
  --         right = { { 'lineinfo' }, { 'percent' } },
  --       },
  --       component = {
  --         linecount = "%{line('$')}",
  --       },
  --       component_function = {
  --         filename = 'LightlineFilename',
  --         branch = 'LightlineBranch',
  --         diff = 'LightlineDiff',
  --         diagnostics = 'LightlineDiagnostics',
  --         selectioncount = 'LightlineSelectionCount',
  --       },
  --       separator = { left = '', right = '' },
  --       subseparator = { left = '', right = '|' },
  --     }
  --
  --     -- Define Vimscript functions
  --     vim.cmd([[
  --       function! LightlineFilename()
  --         let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
  --         let path = expand('%:p:h:t')
  --         let modified = &modified ? '[+]' : ''
  --         let readonly = &readonly ? '[-]' : ''
  --         return path . '/' . filename . ' ' . readonly . modified
  --       endfunction
  --
  --       function! LightlineBranch()
  --         return FugitiveHead()
  --       endfunction
  --
  --       function! LightlineDiff()
  --         let [a,m,r] = GitGutterGetHunkSummary()
  --         return printf('+%d ~%d -%d', a, m, r)
  --       endfunction
  --
  --       function! LightlineDiagnostics() abort
  --         let l:counts = luaeval('vim.diagnostic.get(0)')
  --         let l:all_errors = l:counts.errors
  --         let l:all_warnings = l:counts.warnings
  --         let l:all_info = l:counts.info
  --         let l:all_hints = l:counts.hints
  --         let l:result = ''
  --         if l:all_errors > 0
  --           let l:result .= '󰅚 ' . l:all_errors . ' '
  --         endif
  --         if l:all_warnings > 0
  --           let l:result .= ' ' . l:all_warnings . ' '
  --         endif
  --         if l:all_info > 0
  --           let l:result .= '󰋽 ' . l:all_info . ' '
  --         endif
  --         if l:all_hints > 0
  --           let l:result .= '󰘥 ' . l:all_hints . ' '
  --         endif
  --         return l:result
  --       endfunction
  --
  --       function! LightlineSelectionCount()
  --         let l:selected = line('.') == line('v') ? abs(col('.') - col('v')) + 1 : abs(line('.') - line('v')) + 1
  --         return '礪' . l:selected
  --       endfunction
  --     ]])
  --   end,
  -- },
}
