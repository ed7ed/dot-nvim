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

local function snacks_picker(picker, opts)
  return function()
    require("snacks").picker[picker](opts)
  end
end

function M.random_quote()
  local idx = (tonumber(vim.uv.hrtime()) % #M.quotes) + 1
  return M.quotes[idx]
end

function M.shortcuts()
  return {
    { icon = "󰈞 ", desc = "Files ", group = "Label", key = "f", action = snacks_picker("files") },
    { icon = "󰊄 ", desc = "Grep ", group = "DiagnosticHint", key = "g", action = snacks_picker("grep") },
    { icon = "󰋚 ", desc = "Recent ", group = "Number", key = "r", action = snacks_picker("recent") },
    { icon = "󰠮 ", desc = "Notes ", group = "String", key = "z", action = "ZkNotes" },
    {
      icon = "󰒓 ",
      desc = "Config ",
      group = "Constant",
      key = "c",
      action = snacks_picker("files", { cwd = vim.fn.stdpath("config") }),
    },
    { icon = "󰈆 ", desc = "Quit ", group = "DiagnosticError", key = "q", action = "qa" },
  }
end

function M.footer(elapsed_ms)
  local stats = require("dashboard.utils").get_package_manager_stats()
  local v = vim.version()

  return {
    "",
    string.format(
      "%s v%d.%d.%d  •  󰏖 %d plugins  •  󱎫 %.1fms",
      M.sections.footer_marker,
      v.major,
      v.minor,
      v.patch,
      stats.count,
      elapsed_ms
    ),
    "",
    "“" .. M.random_quote() .. "”",
  }
end

return M
