return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Set header
    dashboard.section.header.val = {
      "                                                   ",
      " ███╗   ███╗███████╗ ██████╗ ██╗   ██╗██╗ ██████╗  ",
      " ████╗ ████║██╔════╝██╔═══██╗██║   ██║██║██╔════╝  ",
      " ██╔████╔██║█████╗  ██║   ██║██║   ██║██║██║  ███╗ ",
      " ██║╚██╔╝██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║   ██║ ",
      " ██║ ╚═╝ ██║███████╗╚██████╔╝ ╚████╔╝ ██║╚██████╔╝ ",
      " ╚═╝     ╚═╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝ ╚═════╝  ",
      "                                                   ",
    }

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
      dashboard.button("-", "  > Oil explorer", "<cmd>Oil<CR>"),
      dashboard.button("SPC fe", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
      dashboard.button("SPC ff", "󰱼  > Find File", "<cmd>Telescope find_files<CR>"),
      dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
      dashboard.button("q", "  > Quit NVIM", "<cmd>qa<CR>"),
    }

    local v = vim.version()
    local version = " v" .. v.major .. "." .. v.minor .. "." .. v.patch

    -- Define a function for updating the footer, including dynamic datetime
    local function updateFooter()
      local datetime = os.date(" %d-%m-%Y 󱑏 %H:%M:%S")
      local stats = require("lazy").stats()
      local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
      dashboard.section.footer.val = {
        "",
        "",
        version,
        "",
        datetime,
        "",
        "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms",
      }
    end

    -- Autocommand group for LazyVimStarted
    local alphaGroup = vim.api.nvim_create_augroup("AlphaInit", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = alphaGroup,
      pattern = "LazyVimStarted",
      callback = function()
        updateFooter()
        alpha.redraw()
      end,
    })

    alpha.setup(dashboard.opts)

    -- Disable folding on the alpha buffer
    vim.api.nvim_create_autocmd("FileType", {
      group = alphaGroup,
      pattern = "alpha",
      command = "setlocal nofoldenable",
    })
  end,
}
