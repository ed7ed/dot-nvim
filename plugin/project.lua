vim.api.nvim_create_autocmd({ "BufEnter", "LspAttach" }, {
  group = vim.api.nvim_create_augroup("project-root", { clear = true }),
  callback = function(args)
    local buf = args.buf
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
      return
    end

    local root = require("project_root").resolve(buf)

    if root and root ~= vim.fn.getcwd() then
      pcall(vim.fn.chdir, root)
    end
  end,
})
