return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
  },
  keys = {
    {
      "<leader>on",
      function()
        local obsidian = require("obsidian")
        -- Check if current buffer is inside vaults directory
        local vaults_path = vim.fn.expand("~/vaults")
        local buf_path = vim.api.nvim_buf_get_name(0)
        local in_vault = buf_path:find(vaults_path, 1, true) ~= nil

        -- If not in a workspace, default to google-drive for note creation
        if not in_vault then
          vim.cmd("Obsidian workspace google-drive")
        end
        vim.cmd("Obsidian new")
      end,
      desc = "Obsidian: New Note (Global)",
    },
    {
      "<leader>os",
      function()
        -- Direct access to the google-drive workspace path for search
        local vaults_path = vim.fn.expand("~/vaults/google-drive")
        require("snacks").picker.files({ cwd = vaults_path })
      end,
      desc = "Obsidian: Search Files (Global)",
    },
    { "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: Quick Switch" },
    {
      "<leader>ow",
      "<cmd>Obsidian workspace<cr>",
      desc = "Obsidian: Switch Workspace",
    },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: Backlinks" },
    {
      "<leader>ot",
      function()
        local obsidian = require("obsidian")
        local vaults_path = vim.fn.expand("~/vaults")
        local buf_path = vim.api.nvim_buf_get_name(0)
        local in_vault = buf_path:find(vaults_path, 1, true) ~= nil

        if not in_vault then
          vim.cmd("Obsidian workspace google-drive")
        end
        vim.cmd("Obsidian today")
      end,
      desc = "Obsidian: Today's Note (Global)",
    },
    {
      "<leader>oz",
      function()
        vim.notify("Starting Obsidian sync... (Desktop notification will follow on completion)", vim.log.levels.INFO)
        vim.fn.jobstart({ "systemctl", "--user", "start", "rclone-sync.service" }, {
          on_exit = function(_, code, _)
            if code == 0 then
              vim.notify("Obsidian sync triggered (rclone-sync.service started)", vim.log.levels.INFO)
            else
              vim.notify("Failed to start rclone-sync.service (exit code: " .. tostring(code) .. ")", vim.log.levels.ERROR)
            end
          end,
        })
      end,
      desc = "Obsidian: Force Sync (Trigger Service)",
    },
  },
  config = function(_, opts)
    require("obsidian").setup(opts)

    -- Force conceallevel=2 for markdown files in the Obsidian vault
    -- This is more reliable than the plugin option alone
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        local vaults_path = vim.fn.expand("~/vaults")
        if filepath:find(vaults_path, 1, true) then
          vim.opt_local.conceallevel = 2
        end
      end,
    })
  end,
  opts = {
    workspaces = {
      {
        name = "google-drive",
        path = "~/vaults/google-drive",
      },
      {
        name = "personal",
        path = "~/vaults/personal",
      },
      {
        name = "work",
        path = "~/vaults/work",
      },
    },
    picker = {
      name = "snacks.nvim",
    },
    notes_subdir = "notes",
    new_notes_location = "notes_subdir",
    -- Custom note ID function to use the title as the filename
    note_id_func = function(title)
      if title ~= nil then
        -- Convert title to valid filename
        return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If no title, use timestamp
        return tostring(os.time())
      end
    end,
    daily_notes = {
      folder = "daily",
    },
    completion = {
      nvim_cmp = false,
      min_chars = 2,
    },
    attachments = {
      folder = "assets/imgs",
    },
    ui = {
      enable = true, -- set to false to disable all additional syntax features
      update_debounce = 200,
      -- Set to 1 or 2 to enable Obsidian's additional syntax features
      conceallevel = 2,
    },
    legacy_commands = false,
  },
}
