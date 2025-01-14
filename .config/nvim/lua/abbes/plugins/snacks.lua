return {
  {
    "folke/snacks.nvim",
    event = "VimEnter",
    cmd = "Snacks",
    priority = 1000,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    init = function()
      -- disable other dashboards to avoid conflicts
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      dashboard = {
        formats = {
          key = function(item)
            return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
          end,
        },
        sections = {
          {
            section = "header",
            header = [[
             ███╗   ███╗███████╗ ██████╗ ██╗   ██╗██╗ ██████╗
             ████╗ ████║██╔════╝██╔═══██╗██║   ██║██║██╔════╝
             ██╔████╔██║█████╗  ██║   ██║██║   ██║██║██║  ███╗
             ██║╚██╔╝██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║   ██║
             ██║ ╚═╝ ██║███████╗╚██████╔╝ ╚████╔╝ ██║╚██████╔╝
             ╚═╝     ╚═╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝ ╚═════╝
            ]]
          },
          { section = "startup" },
          { title = "MRU",            padding = 1 },
          { section = "recent_files", limit = 3,                            padding = 1 },
          { title = "MRU CWD ",       file = vim.fn.fnamemodify(".", ":~"), padding = 1 },
          { section = "recent_files", cwd = true,                           limit = 3,  padding = 1 },
          { title = "Sessions",       padding = 1 },
          { section = "projects",     padding = 1 },
          { title = "Bookmarks",      padding = 1 },
          { section = "keys" },
        },
      },
      -- Keep other features enabled
      scroll = { enabled = false },
      bigfile = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      notifier = {
        enabled = false,
        timeout = 3000,
      },
      quickfile = { enabled = false },
      statuscolumn = { enabled = false },
      words = { enabled = false },
    },
  },
}
