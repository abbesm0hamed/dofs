return {
  {
    "brianhuster/live-preview.nvim",
    lazy = true,
    dependencies = { "brianhuster/autosave.nvim" }, -- Not required, but recomended for autosaving and sync scrolling
    opts = {},
    commands = {
      start = "LivePreview", -- Command to start the live preview server and open the default browser.
      stop = "StopPreview", -- Command to stop the live preview.
    },
    keys = {
      { "<leader>lp", "<cmd>LivePreview<cr>", desc = "Start Live Preview" },
      { "<leader>ls", "<cmd>StopPreview<cr>", desc = "Stop Live Preview" },
    },
    port = 5500, -- Port to run the live preview server on.
    browser = "default", -- Terminal command to open the browser for live-previewing (eg. 'firefox', 'flatpak run com.vivaldi.Vivaldi'). By default, it will use the default browser.
    dynamic_root = false, -- If true, the plugin will set the root directory to the previewed file's directory. If false, the root directory will be the current working directory (`:lua print(vim.uv.cwd())`).
    sync_scroll = false, -- If true, the plugin will sync the scrolling in the browser as you scroll in the Markdown files in Neovim.
  },
}
