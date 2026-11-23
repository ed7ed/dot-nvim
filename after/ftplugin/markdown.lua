local function is_top_h1(lnum)
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "markdown")
  if not ok or not parser then
    return false
  end

  local trees = parser:parse(false)
  local tree = trees and trees[1]
  if not tree then
    return false
  end

  local root = tree:root()
  local row = lnum - 1
  local node = root:named_descendant_for_range(row, 0, row, 0)
  while node do
    if node:type() == "atx_heading" then
      local marker = node:named_child(0)
      local section = node:parent()
      return marker ~= nil and marker:type() == "atx_h1_marker" and section ~= nil and section:parent() == root
    end
    node = node:parent()
  end

  return false
end

function _G.markdown_top_fold()
  return is_top_h1(vim.v.lnum) and ">1" or "="
end

vim.opt_local.foldenable = true
vim.opt_local.foldexpr = "v:lua.markdown_top_fold()"
vim.opt_local.foldlevelstart = 0
vim.opt_local.foldmethod = "expr"
vim.opt_local.textwidth = 0
vim.opt_local.wrapmargin = 0

-- Disable hard wrapping (inserting line breaks automatically)
