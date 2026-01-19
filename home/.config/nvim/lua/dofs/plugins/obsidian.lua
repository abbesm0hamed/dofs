return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    cmd = {
      "ObsidianOpen",
      "ObsidianNew",
      "ObsidianQuickSwitch",
      "ObsidianSearch",
      "ObsidianToday",
      "ObsidianYesterday",
      "ObsidianTomorrow",
      "ObsidianTemplate",
      "ObsidianBacklinks",
      "ObsidianLinks",
      "ObsidianFollowLink",
      "ObsidianRename",
      "ObsidianTags",
    },
    keys = {
      { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: New note" },
      { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: Open in app" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: Search" },
      { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: Quick switch" },
      { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian: Today" },
      { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: Backlinks" },
      { "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Obsidian: Links" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = function()
      local uv = vim.uv or vim.loop
      local joinpath = vim.fs and vim.fs.joinpath or function(...)
        return table.concat({ ... }, "/")
      end
      local dirname = vim.fs and vim.fs.dirname or function(path)
        return vim.fn.fnamemodify(path, ":h")
      end

      local function is_dir(path)
        local stat = uv.fs_stat(path)
        return stat and stat.type == "directory"
      end

      local function find_vault_root(start_dir)
        local dir = vim.fn.fnamemodify(vim.fn.expand(start_dir), ":p")
        while dir and dir ~= "/" do
          if is_dir(joinpath(dir, ".obsidian")) then
            return dir
          end
          local parent = dirname(dir)
          if not parent or parent == dir then
            break
          end
          dir = parent
        end
      end

      local vault = os.getenv("OBSIDIAN_VAULT")
      if vault then
        vault = vim.fn.expand(vault)
        if not is_dir(vault) then
          vault = nil
        end
      end

      if not vault then
        vault = find_vault_root(vim.fn.getcwd())
      end

      if not vault then
        return { _dofs_obsidian_vault_missing = true }
      end

      local templates_subdir = "templates"
      local templates_dir = joinpath(vault, templates_subdir)
      local templates = nil
      if is_dir(templates_dir) then
        templates = {
          subdir = templates_subdir,
          date_format = "%Y-%m-%d",
          time_format = "%H:%M",
        }
      end

      return {
        workspaces = {
          {
            name = "vault",
            path = vault,
          },
        },
        notes_subdir = "notes",
        new_notes_location = "notes_subdir",
        daily_notes = {
          folder = "daily",
          date_format = "%Y-%m-%d",
          alias_format = "%B %-d, %Y",
          template = "daily.md",
        },
        templates = templates,
        note_id_func = function(title)
          local suffix = ""
          if title and #title > 0 then
            suffix = title
              :gsub("%s+", "-")
              :gsub("[^%w%-]", "")
              :lower()
          else
            suffix = tostring(os.time())
          end
          return os.date("%Y%m%d") .. "-" .. suffix
        end,
        note_frontmatter_func = function(note)
          local out = {
            id = note.id,
            aliases = note.aliases,
            tags = note.tags,
          }

          if note.metadata and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end

          return out
        end,
        completion = {
          nvim_cmp = false,
        },
        ui = {
          enable = true,
        },
      }
    end,
    config = function(_, opts)
      if opts and opts._dofs_obsidian_vault_missing then
        vim.notify(
          "obsidian.nvim: vault not found. Set $OBSIDIAN_VAULT to your vault path or start Neovim inside your vault (a folder containing .obsidian/).",
          vim.log.levels.WARN
        )
        return
      end

      require("obsidian").setup(opts)
    end,
  },
}
