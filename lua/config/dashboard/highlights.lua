local M = {}

local HIGHLIGHTS = {
  DashboardHeader = "Title",
  DashboardProjectTitle = "Title",
  DashboardProjectTitleIcon = "Special",
  DashboardProjectIcon = "Directory",
  DashboardMruTitle = "Title",
  DashboardMruIcon = "Special",
  DashboardFiles = "Normal",
  DashboardShortCut = "Keyword",
  DashboardShortCutIcon = "Function",
  DashboardFooter = "Comment",
  DashboardFleetingHash = "DiagnosticSignError",
  DashboardFleetingEmpty = "Comment",
}

function M.apply()
  for group, link in pairs(HIGHLIGHTS) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end
end

function M.setup()
  M.apply()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("dashboard_highlights", { clear = true }),
    desc = "Re-apply dashboard highlight links on colorscheme change",
    callback = M.apply,
  })
end

return M
