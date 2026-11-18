vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Open file at the last position it was edited",
  pattern = "*",

  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end

    local timer = vim.loop.new_timer()
    if timer then
      timer:start(
        0,
        0,
        vim.schedule_wrap(function()
          vim.cmd("normal! zv") -- unfold current
        end)
      )
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("help-window", { clear = true }),
  pattern = "help",
  callback = function()
    vim.cmd.wincmd("L")
  end,
})
