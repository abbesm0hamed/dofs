return {
  {
    "chrisgrieser/nvim-origami",
    event = "BufReadPost",
    opts = {
      keepFoldsAcrossSessions = false,
      pauseFoldsOnSearch = true,
      setupFoldKeymaps = true,
      hOnlyOpensOnFirstColumn = false,
    },
    config = function()
      require("origami").setup({})
    end
  },
}
