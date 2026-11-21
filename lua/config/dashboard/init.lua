local content = require("config.dashboard.content")
local fleeting = require("config.dashboard.fleeting")
local highlights = require("config.dashboard.highlights")

local M = {}

local function setup_dashboard(elapsed_ms)
  local project = content.sections.project
  local mru = content.sections.mru

  require("dashboard").setup({
    theme = "hyper",
    shortcut_type = "number",
    change_to_vcs_root = true,
    config = {
      header = content.header,
      packages = { enable = false },
      project = {
        enable = true,
        limit = project.limit,
        icon = project.icon,
        label = project.label,
        action = function(path)
          require("snacks").picker.files({ cwd = path })
        end,
      },
      mru = {
        enable = true,
        limit = mru.limit,
        icon = mru.icon,
        label = mru.label,
        cwd_only = false,
      },
      shortcut = content.shortcuts(),
      footer = function()
        return content.footer(elapsed_ms)
      end,
    },
  })
end

function M.setup(start_time)
  local t0 = start_time or vim.uv.hrtime()

  highlights.setup()
  fleeting.setup()

  --- Fix dashboard stdin read issue.
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("dashboard_init", { clear = true }),
    desc = "Initialize dashboard unless reading from stdin",
    callback = function()
      if vim.fn.line2byte("$") ~= -1 then
        vim.g.read_from_stdin = 1
        return
      end

      local elapsed_ms = (vim.uv.hrtime() - t0) / 1e6
      setup_dashboard(elapsed_ms)
    end,
  })
end

return M
