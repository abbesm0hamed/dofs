return {
  { -- better % (highlighting, matches across lines, match quotes)
    "andymass/vim-matchup",
    event = "VimEnter", -- cannot load on keys due to highlights
    keys = {
      { "m", "<Plug>(matchup-%)", mode = { "n", "v" }, desc = "Goto Matching Bracket" },
    },
    dependencies = "nvim-treesitter/nvim-treesitter",
    init = function()
      -- if not using biscuits.nvim or nvim_context_vt, use this for context
      vim.g.matchup_matchparen_offscreen = {}
      vim.g.matchup_matchparen_deferred = 1 --improves performance a bit
    end,
  },
  { -- CamelCase Motion plus
    "chrisgrieser/nvim-spider",
    keys = {
      {
        "e",
        "<cmd>lua require('spider').motion('e')<CR>",
        mode = { "n", "o", "x" },
        desc = "󱇫 Spider e",
      },
      {
        "b",
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { "n", "x" }, -- not `o`, since mapped to inner bracket
        desc = "󱇫 Spider b",
      },
    },
  },
}
