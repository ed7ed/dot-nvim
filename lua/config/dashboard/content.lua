local M = {}

M.sections = {
  project = {
    icon = "󰉋 ",
    label = " Recent Projects",
    limit = 4,
  },
  mru = {
    icon = "󰋚 ",
    label = " Recent Files",
    limit = 6,
  },
  fleeting = {
    icon = "󰠮 ",
    label = " Fleeting Notes",
    limit = 5,
  },
  footer_marker = "⚡ Neovim",
}

M.header = {
  "",
  "      ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗    ",
  "      ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║    ",
  "      ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║    ",
  "      ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║    ",
  "      ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║    ",
  "      ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝    ",
  "",
}

M.quotes = {
  "Simplicity is prerequisite for reliability. — Edsger W. Dijkstra",
  "Make it work, make it right, make it fast. — Kent Beck",
  "First, solve the problem. Then, write the code. — John Johnson",
  "Programs must be written for people to read, and only incidentally for machines to execute. — Hal Abelson",
  "The best way to predict the future is to invent it. — Alan Kay",
  "Premature optimization is the root of all evil. — Donald Knuth",
  "Controlling complexity is the essence of computer programming. — Brian Kernighan",
}

function M.random_quote()
  local idx = (tonumber(vim.uv.hrtime()) % #M.quotes) + 1
  return M.quotes[idx]
end

--- dashboard-nvim serializes callback functions via string.dump(), which drops upvalues.
--- Keep every shortcut action self-contained with no captured locals.
function M.shortcuts()
  return {
    {
      icon = "󰈞 ",
      desc = "Files ",
      group = "Label",
      key = "f",
      action = function()
        require("snacks").picker.files()
      end,
    },
    {
      icon = "󰊄 ",
      desc = "Grep ",
      group = "DiagnosticHint",
      key = "g",
      action = function()
        require("snacks").picker.grep()
      end,
    },
    {
      icon = "󰋚 ",
      desc = "Recent ",
      group = "Number",
      key = "r",
      action = function()
        require("snacks").picker.recent()
      end,
    },
    { icon = "󰠮 ", desc = "Notes ", group = "String", key = "z", action = "ZkNotes" },
    {
      icon = "󰒓 ",
      desc = "Config ",
      group = "Constant",
      key = "c",
      action = function()
        require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
      end,
    },
    { icon = "󰈆 ", desc = "Quit ", group = "DiagnosticError", key = "q", action = "qa" },
  }
end

function M.footer(elapsed_ms)
  local stats = require("dashboard.utils").get_package_manager_stats()
  local v = vim.version()
  local ms = elapsed_ms or M.startup_ms
  local timing = ms and string.format("  •  󱎫 %.1fms", ms) or ""

  return {
    "",
    string.format(
      "%s v%d.%d.%d  •  󰏖 %d plugins%s",
      M.sections.footer_marker,
      v.major,
      v.minor,
      v.patch,
      stats.count,
      timing
    ),
    "",
    "“" .. M.random_quote() .. "”",
  }
end

return M
