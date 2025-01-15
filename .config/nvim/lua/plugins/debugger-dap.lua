return {
  {
    "mfussenegger/nvim-dap",
    recommended = true,
    desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",

    dependencies = {
      "rcarriga/nvim-dap-ui",
      -- virtual text for the debugger
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },

  -- stylua: ignore
  keys = {
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
    { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dj", function() require("dap").down() end, desc = "Down" },
    { "<leader>dk", function() require("dap").up() end, desc = "Up" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>ds", function() require("dap").session() end, desc = "Session" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
  },

    config = function()
      -- load mason-nvim-dap here, after all adapters have been setup
      if LazyVim.has("mason-nvim-dap.nvim") then
        require("mason-nvim-dap").setup(LazyVim.opts("mason-nvim-dap.nvim"))
      end

      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(LazyVim.config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      -- setup dap config by VsCode launch.json file
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "󱂬 dap-ui",
      },
      {
        "<leader>di",
        function()
          require("dapui").float_element("repl", { enter = true })
        end,
        desc = " REPL",
      },
      {
        "<leader>dl",
        function()
          require("dapui").float_element("breakpoints", { enter = true })
        end,
        desc = " List Breakpoints",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        mode = { "n", "x" },
        desc = " Eval",
      },
    },
    opts = {
      controls = {
        enabled = true,
        element = "scopes",
      },
      mappings = {
        expand = { "<Tab>", "<2-LeftMouse>" }, -- 2-LeftMouse = Double Click
        open = "<CR>",
      },
      floating = {
        border = vim.g.borderStyle,
        mappings = { close = { "q", "<Esc>", "<D-w>" } },
      },
      layouts = {
        {
          position = "right",
          size = 40, -- width
          elements = {
            { id = "scopes", size = 0.8 }, -- Variables
            { id = "stacks", size = 0.2 }, -- stracktracing
            -- { id = "watches", size = 0.15 }, -- Expressions
          },
        },
      },
    },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {},
  },
  { "nvim-neotest/nvim-nio" },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
      },
    },
    -- mason-nvim-dap is loaded when nvim-dap loads
    config = function() end,
  },
  { -- debugger for nvim-lua
    "jbyuki/one-small-step-for-vimkind",
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      require("dap").configurations.lua = {
        { type = "nlua", request = "attach", name = "Attach to running Neovim instance" },
      }
      require("dap").adapters.nlua = function(callback, config)
        callback({
          type = "server",
          host = config.host or "127.0.0.1",
          port = config.port or 8086,
        })
      end
    end,
    keys = {
      -- INFO is the only one that needs manual starting, other debuggers
      -- start with `continue` by themselves
      {
        "<leader>dn",
        function()
          require("osv").run_this()
        end,
        ft = "lua",
        desc = " nvim-lua debugger",
      },
    },
  },
  { -- debugger preconfig for python
    "mfussenegger/nvim-dap-python",
    mason_dependencies = "debugpy",
    ft = "python",
    config = function()
      -- 1. use the debugypy installation by mason
      -- 2. deactivate the annoying auto-opening the console by redirecting
      -- to the internal console
      local debugpyPythonPath = require("mason-registry").get_package("debugpy"):get_install_path()
        .. "/venv/bin/python3"
      require("dap-python").setup(debugpyPythonPath, { console = "internalConsole" })
    end,
  },
}
