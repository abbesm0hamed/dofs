return {
  "kelly-lin/ranger.nvim",
  event = "VeryLazy",
  config = function()
    local ranger_nvim = require("ranger-nvim")
    ranger_nvim.setup({
      Replace_netrw = false,
      enable_cmds = false,
      keybinds = {
        ["ov"] = ranger_nvim.OPEN_MODE.vsplit,
        ["oh"] = ranger_nvim.OPEN_MODE.split,
        ["ot"] = ranger_nvim.OPEN_MODE.tabedit,
        ["or"] = ranger_nvim.OPEN_MODE.rifle,
      },
      ui = {
        border = "none",
        height = 1,
        width = 1,
        x = 0.5,
        y = 0.5,
      },
    })
    vim.api.nvim_set_keymap("n", "<leader>rr", "", {
      noremap = true,
      callback = function()
        require("ranger-nvim").open(true)
      end,
    })
  end,
}
