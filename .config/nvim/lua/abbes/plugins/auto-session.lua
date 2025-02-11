return {
  "rmagatti/auto-session",
  config = function()
    local auto_session = require("auto-session")

    auto_session.setup({
      auto_restore_enabled = false,
      auto_session_suppress_dirs = { "~/", "~/Downloads", "~/Documents", "~/.config" },
      session_lens = {
        buftypes_to_ignore = {}, -- List of buffer types to ignore
        load_on_setup = true,    -- Load session-lens on setup
        theme_conf = { border = true },
        previewer = false,
      },
    })

    -- Key mappings
    local keymap = vim.keymap
    keymap.set("n", "<leader>sl", require("auto-session.session-lens").search_session, {
      noremap = true,
      desc = "Search for sessions",
    })
    keymap.set(
      "n",
      "<leader>ls",
      "<cmd>SessionRestore<CR>:echo 'Session restored'<CR>",
      { desc = "Restore session for current directory" }
    )
    keymap.set(
      "n",
      "<leader>ss",
      "<cmd>SessionSave<CR>:echom 'Session saved'<CR>",
      { desc = "Save session for current directory" }
    )
  end,
}
