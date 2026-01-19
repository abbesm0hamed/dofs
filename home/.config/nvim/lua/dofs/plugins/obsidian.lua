return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = false, -- Load immediately so commands work from anywhere
  event = {
    "BufReadPre " .. vim.fn.expand("~") .. "/vaults/**.md",
    "BufNewFile " .. vim.fn.expand("~") .. "/vaults/**.md",
  },
  ft = "markdown",
  keys = {
    -- Core workflow keymaps
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: New Note" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: Search Notes" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: Quick Switch" },
    { "<leader>ow", "<cmd>ObsidianWorkspace<cr>", desc = "Obsidian: Switch Workspace" },

    -- Daily notes
    { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian: Today's Note" },
    { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Obsidian: Yesterday's Note" },
    { "<leader>om", "<cmd>ObsidianTomorrow<cr>", desc = "Obsidian: Tomorrow's Note" },

    -- Navigation & linking
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: Show Backlinks" },
    { "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Obsidian: Show Links" },
    { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Obsidian: Follow Link" },

    -- Templates & tags
    { "<leader>oT", "<cmd>ObsidianTemplate<cr>", desc = "Obsidian: Insert Template" },
    { "<leader>og", "<cmd>ObsidianTags<cr>", desc = "Obsidian: Search Tags" },

    -- File management
    { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Obsidian: Rename Note" },
    { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: Open in App" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
  },
  opts = {
    -- Workspaces configuration
    workspaces = {
      {
        name = "personal",
        path = "~/vaults/personal",
      },
      {
        name = "work",
        path = "~/vaults/work",
      },
    },

    -- Use snacks.nvim picker for all search operations
    picker = {
      name = "snacks.nvim",
    },

    -- Note creation and path configuration
    notes_subdir = "notes",

    -- New note location - allows you to specify path when creating
    new_notes_location = "notes_subdir",

    -- Custom note ID function for flexible file paths
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        -- Convert title to valid filename
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If no title, use timestamp
        suffix = tostring(os.time())
      end
      return suffix
    end,

    -- Note path function - customize where notes are created
    note_path_func = function(spec)
      -- spec.title: the note title
      -- spec.id: the note ID
      -- spec.dir: the workspace directory

      local path = spec.dir / tostring(spec.id)
      return path:with_suffix(".md")
    end,

    -- Disable legacy commands (cleaner interface)
    legacy_commands = false,

    -- Daily notes configuration
    daily_notes = {
      folder = "daily",
      date_format = "%Y-%m-%d",
      alias_format = "%B %-d, %Y",
      default_tags = { "daily-notes" },
      template = nil,
    },

    -- Completion with blink.cmp
    completion = {
      nvim_cmp = false, -- Disable nvim-cmp
      min_chars = 2,
    },

    -- Image handling with snacks.nvim
    attachments = {
      img_folder = "assets/imgs",
      img_text_func = function(client, path)
        path = client:vault_relative_path(path) or path
        return string.format("![%s](%s)", path.name, path)
      end,
    },

    -- UI configuration
    ui = {
      enable = true,
      update_debounce = 200,
      max_file_length = 5000,
      checkboxes = {
        [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
        ["x"] = { char = "", hl_group = "ObsidianDone" },
        [">"] = { char = "", hl_group = "ObsidianRightArrow" },
        ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
        ["!"] = { char = "", hl_group = "ObsidianImportant" },
      },
      bullets = { char = "•", hl_group = "ObsidianBullet" },
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
      block_ids = { hl_group = "ObsidianBlockID" },
      hl_groups = {
        ObsidianTodo = { bold = true, fg = "#f78c6c" },
        ObsidianDone = { bold = true, fg = "#89ddff" },
        ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
        ObsidianTilde = { bold = true, fg = "#ff5370" },
        ObsidianImportant = { bold = true, fg = "#d73128" },
        ObsidianBullet = { bold = true, fg = "#80cbc4" },
        ObsidianRefText = { underline = true, fg = "#c792ea" },
        ObsidianExtLinkIcon = { fg = "#c792ea" },
        ObsidianTag = { italic = true, fg = "#89ddff" },
        ObsidianBlockID = { italic = true, fg = "#89ddff" },
        ObsidianHighlightText = { bg = "#75662e" },
      },
    },

    -- Disable default mappings (we define custom ones above)
    mappings = {},

    -- Templates configuration
    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        yesterday = function()
          return os.date("%Y-%m-%d", os.time() - 86400)
        end,
        tomorrow = function()
          return os.date("%Y-%m-%d", os.time() + 86400)
        end,
      },
    },

    -- Follow URL function
    follow_url_func = function(url)
      vim.fn.jobstart({ "xdg-open", url }) -- Linux
      -- vim.fn.jobstart({ "open", url }) -- macOS
      -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
    end,

    -- Wiki link settings
    wiki_link_func = "use_alias_only",

    -- Markdown link settings
    preferred_link_style = "wiki",

    -- Disable URL concealing for better visibility
    disable_frontmatter = false,

    -- Frontmatter config
    note_frontmatter_func = function(note)
      local out = { id = note.id, aliases = note.aliases, tags = note.tags }

      -- Add metadata
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end

      return out
    end,

    -- YAML frontmatter settings
    yaml_parser = "native",
  },

  config = function(_, opts)
    -- Ensure workspace directories exist to prevent plugin failure
    local workspaces = opts.workspaces or {}
    for _, workspace in ipairs(workspaces) do
      local path = workspace.path
      if path and type(path) == "string" then
        path = vim.fn.expand(path)
        if vim.fn.isdirectory(path) == 0 then
          vim.notify("Obsidian: Creating missing vault directory: " .. path, vim.log.levels.INFO)
          vim.fn.mkdir(path, "p")
        end
      end
    end

    require("obsidian").setup(opts)

    -- Additional configuration for blink.cmp integration
    -- Make sure obsidian completion source is registered with blink
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        -- Enable blink completion for obsidian
        if pcall(require, "blink.cmp") then
          -- blink.cmp will automatically pick up the obsidian source
          vim.b.completion_enabled = true
        end
      end,
    })
  end,
}
