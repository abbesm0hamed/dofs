local u = require("abbes.config.utils")
--------------------------------------------------------------------------------

local function dapConfig()
	--[[ Sign-Icons & Highlights ]]
	local sign = vim.fn.sign_define
	local hintBg = u.getHighlightValue("DiagnosticVirtualTextHint", "bg")
	vim.api.nvim_set_hl(0, "DapPause", { bg = hintBg })
	local infoBg = u.getHighlightValue("DiagnosticVirtualTextInfo", "bg")
	vim.api.nvim_set_hl(0, "DapBreak", { bg = infoBg })

	sign("DapStopped", { text = "", texthl = "DiagnosticHint", linehl = "DapPause" })
	sign("DapBreakpoint", { text = "", texthl = "DiagnosticInfo", linehl = "DapBreak" })
	sign("DapBreakpointRejected", { text = "", texthl = "DiagnosticError" })

	--[[ auto-open/close the dap-ui ]]
	local listener = require("dap").listeners.before
	listener.attach.dapui_config = function() require("dapui").open() end
	listener.launch.dapui_config = function() require("dapui").open() end
	listener.event_terminated.dapui_config = function() require("dapui").close() end
	listener.event_exited.dapui_config = function() require("dapui").close() end

	--[[ lualine components ]]
	local breakpointHl = vim.fn.sign_getdefined("DapBreakpoint")[1].texthl
	local breakpointFg = u.getHighlightValue(breakpointHl, "fg")
	u.addToLuaLine("sections", "lualine_y", {
		color = { fg = breakpointFg },
		function()
			local breakpoints = require("dap.breakpoints").get()
			local breakpointSum = 0
			for buf, _ in pairs(breakpoints) do
				breakpointSum = breakpointSum + #breakpoints[buf]
			end
			if breakpointSum == 0 then return "" end
			local breakpointIcon = vim.fn.sign_getdefined("DapBreakpoint")[1].text
			return breakpointIcon .. tostring(breakpointSum)
		end,
	})
	u.addToLuaLine("winbar", "lualine_z", function()
		local dapStatus = require("dap").status()
		if dapStatus == "" then return "" end
		return "  " .. dapStatus
	end)
	-- require("config.theme-customization").reloadTheming()
end

---PENDING https://github.com/mfussenegger/nvim-dap/issues/792
---@param dir "next"|"prev"
local function gotoBreakpoint(dir)
	local breakpoints = require("dap.breakpoints").get()
	if #breakpoints == 0 then
		vim.notify("No breakpoints set", vim.log.levels.WARN)
		return
	end
	local points = {}
	for bufnr, buffer in pairs(breakpoints) do
		for _, point in ipairs(buffer) do
			table.insert(points, { bufnr = bufnr, line = point.line })
		end
	end

	local current = {
		bufnr = vim.api.nvim_get_current_buf(),
		line = vim.api.nvim_win_get_cursor(0)[1],
	}

	local nextPoint
	for i = 1, #points do
		local isAtBreakpointI = points[i].bufnr == current.bufnr and points[i].line == current.line
		if isAtBreakpointI then
			local nextIdx = dir == "next" and i + 1 or i - 1
			if nextIdx > #points then nextIdx = 1 end
			if nextIdx == 0 then nextIdx = #points end
			nextPoint = points[nextIdx]
			break
		end
	end
	if not nextPoint then nextPoint = points[1] end

	vim.cmd(("buffer +%s %s"):format(nextPoint.line, nextPoint.bufnr))
end

--------------------------------------------------------------------------------

return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			-- INFO toggling breakpoints and "Continue" command done via nvim-recorder
			-- stylua: ignore
			{ "<leader>dc", function() require("dap").clear_breakpoints() end, desc = " Clear All Breakpoints" },
			{ "<leader>dr", function() require("dap").restart() end, desc = " Restart" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = " Terminate" },
			{ "gb", function() gotoBreakpoint("next") end, desc = " Next Breakpoint" },
			{ "gB", function() gotoBreakpoint("prev") end, desc = " Previous Breakpoint" },
		},
		init = function() u.leaderSubkey("d", " Debugger", { "n", "x" }) end,
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "delve" })
				end,
			},
			{
				"leoluz/nvim-dap-go",
				config = true,
			},
		},
		config = dapConfig,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = "mfussenegger/nvim-dap",
		keys = {
			{ "<leader>du", function() require("dapui").toggle() end, desc = "󱂬 dap-ui" },
			{
				"<leader>di",
				function() require("dapui").float_element("repl", { enter = true }) end,
				desc = " REPL",
			},
			{
				"<leader>dl",
				function() require("dapui").float_element("breakpoints", { enter = true }) end,
				desc = " List Breakpoints",
			},
			{
				"<leader>de",
				function() require("dapui").eval() end,
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
					size = 40,                 -- width
					elements = {
						{ id = "scopes", size = 0.8 }, -- Variables
						{ id = "stacks", size = 0.2 }, -- stracktracing
						-- { id = "watches", size = 0.15 }, -- Expressions
					},
				},
			},
		},
	},
	-- { -- debugger for nvim-lua
	-- 	"jbyuki/one-small-step-for-vimkind",
	-- 	dependencies = "mfussenegger/nvim-dap",
	-- 	config = function()
	-- 		require("dap").configurations.lua = {
	-- 			{ type = "nlua", request = "attach", name = "Attach to running Neovim instance" },
	-- 		}
	-- 		require("dap").adapters.nlua = function(callback, config)
	-- 			callback {
	-- 				type = "server",
	-- 				host = config.host or "127.0.0.1",
	-- 				port = config.port or 8086,
	-- 			}
	-- 		end
	-- 	end,
	-- 	keys = {
	-- 		-- INFO is the only one that needs manual starting, other debuggers
	-- 		-- start with `continue` by themselves
	-- 		{
	-- 			"<leader>dn",
	-- 			function() require("osv").run_this() end,
	-- 			ft = "lua",
	-- 			desc = " nvim-lua debugger",
	-- 		},
	-- 	},
	-- },
	-- { -- debugger preconfig for python
	-- 	"mfussenegger/nvim-dap-python",
	-- 	mason_dependencies = "debugpy",
	-- 	ft = "python",
	-- 	config = function()
	-- 		-- 1. use the debugypy installation by mason
	-- 		-- 2. deactivate the annoying auto-opening the console by redirecting
	-- 		-- to the internal console
	-- 		local debugpyPythonPath = require("mason-registry")
	-- 			.get_package("debugpy")
	-- 			:get_install_path() .. "/venv/bin/python3"
	-- 		require("dap-python").setup(debugpyPythonPath, { console = "internalConsole" })
	-- 	end,
	-- },
}
