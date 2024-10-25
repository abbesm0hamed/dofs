return {
  { -- convenience file operations
    "chrisgrieser/nvim-genghis",
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
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({})
      local keymap = vim.keymap
      keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
}
