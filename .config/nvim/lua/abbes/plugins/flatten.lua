return {
  "willothy/flatten.nvim",
  lazy = false,
  priority = 1001,
  opts = {
    window = {
      open = "current",
    },
    hooks = {
      pre_open = function()
        -- Close toggleterm when an external open request is received
        require("toggleterm").toggle(0)
      end,
      post_open = function(bufnr, winnr, ft)
        if ft == "gitcommit" then
          -- If the file is a git commit, create one-shot autocmd to delete it on write
          vim.api.nvim_create_autocmd("BufWritePost", {
            buffer = bufnr,
            once = true,
            callback = function()
              -- This is a bit of a hack, but if you run bufdelete immediately
              -- the shell can occasionally freeze
              vim.defer_fn(function()
                vim.api.nvim_buf_delete(bufnr, {})
              end, 50)
            end,
          })
        else
          -- If it's a normal file, then reopen the terminal, then switch back to the newly opened window
          require("toggleterm").toggle(0)
          vim.api.nvim_set_current_win(winnr)
        end
      end,
      block_end = function()
        -- After blocking ends (for a git commit, etc), reopen the terminal
        require("toggleterm").toggle(0)
      end,
    },
  },
}
