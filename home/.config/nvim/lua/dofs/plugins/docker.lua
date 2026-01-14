return {
  {
    "mgierada/lazydocker.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    cmd = "Lazydocker",
    keys = {
      {
        "<leader>ld",
        function()
          -- Try the plugin command first
          local ok, _ = pcall(vim.cmd, "Lazydocker")
          if not ok then
            -- Fallback to opening lazydocker in betterTerm
            require("betterTerm").open(3) -- Use terminal slot 3 for lazydocker
            vim.defer_fn(function()
              vim.cmd("startinsert")
              vim.api.nvim_feedkeys("lazydocker\r", "t", false)
            end, 100)
          end
        end,
        desc = "Open LazyDocker",
      },
    },
    config = function()
      require("lazydocker").setup()
    end,
  },
}
