return {
  {
    -- Go development support with struct tags, implements, etc.
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
    build = function()
      -- Add error handling and delay to prevent startup issues
      vim.defer_fn(function()
        local ok, err = pcall(vim.cmd.GoInstallDeps)
        if not ok then
          vim.notify("gopher.nvim: " .. tostring(err), vim.log.levels.WARN)
        end
      end, 100)
    end,
    keys = {
      { "<leader>gts", "<cmd>GoTagAdd json<cr>", desc = "Add JSON tags", ft = "go" },
      { "<leader>gty", "<cmd>GoTagAdd yaml<cr>", desc = "Add YAML tags", ft = "go" },
      { "<leader>gtr", "<cmd>GoTagRm<cr>", desc = "Remove tags", ft = "go" },
      { "<leader>gie", "<cmd>GoIfErr<cr>", desc = "Add if err", ft = "go" },
      { "<leader>gim", "<cmd>GoImpl<cr>", desc = "Generate interface implementation", ft = "go" },
    },
  },
  {
    -- Comprehensive Go tooling and LSP enhancements
    "ray-x/go.nvim",
    ft = { "go", "gomod", "gowork", "gotmpl" },
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      -- Disable features handled by other plugins or not needed
      goimports = "gopls", -- Use gopls for imports
      fillstruct = "gopls", -- Use gopls for struct filling
      dap_debug = false, -- Disable if you don't use DAP
      dap_debug_gui = false,
      test_runner = "go", -- Use basic go test, neotest handles advanced testing
      run_in_floaterm = false, -- Disable if you don't use floaterm
      trouble = false, -- Disable if you don't use trouble.nvim
      luasnip = false, -- Disable if you don't use luasnip
      -- Prevent conflicts with other plugins
      lsp_cfg = false, -- Don't let go.nvim configure LSP
      lsp_keymaps = false, -- Use your own keymaps
      diagnostic = {
        underline = false, -- Prevent diagnostic conflicts
        virtual_text = false,
        signs = false,
      },
    },
    build = function()
      -- Safer build process with error handling
      vim.defer_fn(function()
        local ok, go_install = pcall(require, "go.install")
        if ok then
          local install_ok, err = pcall(go_install.update_all_sync)
          if not install_ok then
            vim.notify("go.nvim install failed: " .. tostring(err), vim.log.levels.WARN)
          end
        end
      end, 200)
    end,
    keys = {
      { "<leader>gr", "<cmd>GoRun<cr>", desc = "Go run", ft = "go" },
      { "<leader>gb", "<cmd>GoBuild<cr>", desc = "Go build", ft = "go" },
      { "<leader>gt", "<cmd>GoTest<cr>", desc = "Go test", ft = "go" },
      { "<leader>gT", "<cmd>GoTestPkg<cr>", desc = "Go test package", ft = "go" },
      { "<leader>gc", "<cmd>GoCoverage<cr>", desc = "Go coverage", ft = "go" },
    },
  },
  {
    -- Enhanced testing with Go support
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-go",
    },
    opts = {
      adapters = {
        ["neotest-go"] = {
          experimental = {
            test_table = true, -- Enable table-driven tests support
          },
          args = { "-count=1", "-timeout=60s", "-race" },
          recursive_run = true,
        },
      },
    },
  },
}
