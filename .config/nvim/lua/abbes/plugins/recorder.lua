local u = require("abbes.config.utils")
--------------------------------------------------------------------------------

return {
  -- { -- better macros
  -- 	"chrisgrieser/nvim-recorder",
  -- 	keys = {
  -- 		{ "9", desc = " Start/Stop Recording" },
  -- 		{ "8", desc = "/ Continue/Play" },
  -- 		{ "7", desc = "/ Breakpoint" },
  -- 	},
  -- 	opts = {
  -- 		clear = true,
  -- 		logLevel = vim.log.levels.TRACE,
  -- 		mapping = { startStopRecording = "0", playMacro = "9", switchSlot = "<C-0>", editMacro = "c0", yankMacro = "y0", deleteAllMacros = "d0", addBreakPoint = "8" },
  -- 		dapSharedKeymaps = true,
  -- 		performanceOpts = { countThreshold = 10 },
  -- 	},
  -- 	config = function(_, opts)
  -- 		require("recorder").setup(opts)
  -- 		u.addToLuaLine("winbar", "lualine_z", require("recorder").recordingStatus)
  -- 		u.addToLuaLine("sections", "lualine_y", require("recorder").displaySlots)
  -- 	end,
  -- },
}
