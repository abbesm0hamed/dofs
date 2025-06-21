return {
  { -- convenience file operations
    "chrisgrieser/nvim-genghis",
    lazy = true,
    dependencies = "stevearc/dressing.nvim",
    init = function()
      vim.g.genghis_disable_commands = true
    end,
    keys = {
      -- stylua: ignore start
      { "<C-p>", function() require("genghis").copyFilepathWithTilde() end, desc = " Copy path (with ~)" },
      { "<C-t>", function() require("genghis").copyRelativePath() end, desc = " Copy relative path" },
      { "<C-n>", function() require("genghis").copyFilename() end, desc = " Copy filename" },
      { "<C-r>", function() require("genghis").renameFile() end, desc = " Rename file" },
      { "<D-m>", function() require("genghis").moveToFolderInCwd() end, desc = " Move file" },
      { "<leader>x", function() require("genghis").chmodx() end, desc = " chmod +x" },
      { "<A-d>", function() require("genghis").duplicateFile() end, desc = " Duplicate file" },
      { "<D-BS>", function() require("genghis").trashFile() end, desc = " Move file to trash" },
      { "<D-n>", function() require("genghis").createNewFile() end, desc = " Create new file" },
      { "X", function() require("genghis").moveSelectionToNewFile() end, mode = "x", desc = " Selection to new file" },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = true,
    opts = {
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = false,
        -- This function defines what is considered a "hidden" file
        is_hidden_file = function(name, bufnr)
          return vim.startswith(name, ".")
        end,
        -- This function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
          return false
        end,
        -- Sort file names in a more intuitive order for humans. Is less performant,
        -- so you may want to set to false if you work with large directories.
        natural_order = true,
        sort = {
          -- sort order can be "asc" or "desc"
          -- see :help oil-columns to see which columns are sortable
          { "type", "asc" },
          { "name", "asc" },
        },
      },
    },
    -- Optional dependencies
    dependencies = {
      "echasnovski/mini.icons",
    },
    config = function()
      require("oil").setup({})
      local keymap = vim.keymap
      keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>ou", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    opts = {
      highlight_hovered_item = true,
      show_guides = true,
      auto_preview = false,
      position = "right",
      relative_width = true,
      width = 25,
      auto_close = false,
      show_numbers = false,
      show_relative_numbers = false,
      show_symbol_details = true,
      preview_bg_highlight = "Pmenu",
      autofold_depth = nil,
      auto_unfold_hover = true,
      fold_markers = { "", "" },
      wrap = false,
      keymaps = { -- These keymaps can be a string or a table for multiple keys
        close = { "<Esc>", "q" },
        goto_location = "<Cr>",
        focus_location = "o",
        hover_symbol = "<C-space>",
        toggle_preview = "K",
        rename_symbol = "r",
        code_actions = "a",
        fold = "h",
        unfold = "l",
        fold_all = "W",
        unfold_all = "E",
        fold_reset = "R",
      },
      lsp_blacklist = {},
      symbol_blacklist = {},
      symbols = {
        File = { icon = "", hl = "@text.uri" },
        Module = { icon = "", hl = "@namespace" },
        Namespace = { icon = "", hl = "@namespace" },
        Package = { icon = "", hl = "@namespace" },
        Class = { icon = "𝓒", hl = "@type" },
        Method = { icon = "ƒ", hl = "@method" },
        Property = { icon = "", hl = "@method" },
        Field = { icon = "", hl = "@field" },
        Constructor = { icon = "", hl = "@constructor" },
        Enum = { icon = "ℰ", hl = "@type" },
        Interface = { icon = "ﰮ", hl = "@type" },
        Function = { icon = "", hl = "@function" },
        Variable = { icon = "", hl = "@constant" },
        Constant = { icon = "", hl = "@constant" },
        String = { icon = "𝓐", hl = "@string" },
        Number = { icon = "#", hl = "@number" },
        Boolean = { icon = "⊨", hl = "@boolean" },
        Array = { icon = "", hl = "@constant" },
        Object = { icon = "⦿", hl = "@type" },
        Key = { icon = "🔐", hl = "@type" },
        Null = { icon = "NULL", hl = "@type" },
        EnumMember = { icon = "", hl = "@field" },
        Struct = { icon = "𝓢", hl = "@type" },
        Event = { icon = "🗲", hl = "@type" },
        Operator = { icon = "+", hl = "@operator" },
        TypeParameter = { icon = "𝙏", hl = "@parameter" },
        Component = { icon = "", hl = "@function" },
        Fragment = { icon = "", hl = "@constant" },
      },
    },
  },
}
