function _G.markdown_top_fold()
  local line = vim.fn.getline(vim.v.lnum)

  if line:match("^# ") then
    return ">1"
  end

  -- Blank lines before a top-level heading belong to current fold.
  if line:match("^%s*$") then
    local next_nonblank = vim.fn.nextnonblank(vim.v.lnum + 1)
    if next_nonblank > 0 and vim.fn.getline(next_nonblank):match("^# ") then
      return 1
    end
  end

  return "="
end

vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.markdown_top_fold()"
vim.opt_local.foldenable = true
vim.opt_local.foldlevelstart = 0
vim.opt_local.textwidth = 0
vim.opt_local.wrapmargin = 0

-- Disable hard wrapping (inserting line breaks automatically)
