local start_time = vim.uv.hrtime()

local header = {
  "",
  "      ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗    ",
  "      ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║    ",
  "      ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║    ",
  "      ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║    ",
  "      ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║    ",
  "      ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝    ",
  "",
}

local quotes = {
  "Simplicity is prerequisite for reliability. — Edsger W. Dijkstra",
  "Make it work, make it right, make it fast. — Kent Beck",
  "First, solve the problem. Then, write the code. — John Johnson",
  "Programs must be written for people to read, and only incidentally for machines to execute. — Hal Abelson",
  "The best way to predict the future is to invent it. — Alan Kay",
  "Premature optimization is the root of all evil. — Donald Knuth",
  "Controlling complexity is the essence of computer programming. — Brian Kernighan",
}

local function render_fleeting_notes(bufnr)
  local ok, zk = pcall(require, "zk")
  if not ok or not zk.fleeting or not zk.fleeting.is_available() then
    return
  end

  local entries = zk.fleeting.get_headers(5)
  local fleeting_section_title = string.format("󰠮  Fleeting Notes (%s)", zk.fleeting.name)

  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local mru_row, title_col, block_width = 1, 0, 50
  local existing_title_row

  for idx, line in ipairs(buf_lines) do
    local s = line:find("󰋚  Recent Files", 1, true)
    if s then
      mru_row = idx
      title_col = s - 1
      block_width = vim.api.nvim_strwidth(line) - title_col
    end
    if line:find(fleeting_section_title, 1, true) then
      existing_title_row = idx
    end
  end

  local footer_row = #buf_lines + 1
  for idx = mru_row + 1, #buf_lines do
    if buf_lines[idx]:find("⚡ Neovim", 1, true) then
      footer_row = idx - 1
      break
    end
  end

  local title_prefix = (" "):rep(title_col)
  local item_prefix = (" "):rep(title_col + 3)

  local function pad_to_block(str)
    local target = title_col + block_width
    local cur = vim.api.nvim_strwidth(str)
    return cur < target and (str .. (" "):rep(target - cur)) or str
  end

  local section_lines = {
    "",
    pad_to_block(title_prefix .. fleeting_section_title),
  }

  for _, entry in ipairs(entries) do
    table.insert(section_lines, pad_to_block(item_prefix .. "# " .. entry.text))
  end

  vim.bo[bufnr].modifiable = true
  local insert_start = existing_title_row and (existing_title_row - 2) or (footer_row - 1)
  local insert_end = footer_row - 1
  vim.api.nvim_buf_set_lines(bufnr, insert_start, insert_end, false, section_lines)

  local ns = vim.api.nvim_create_namespace("dashboard_fleeting")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local title_line_idx = insert_start + 1
  local title_line = section_lines[2]
  local icon_start = title_col

  vim.api.nvim_buf_set_extmark(bufnr, ns, title_line_idx, 0, {
    end_col = #title_line,
    hl_group = "DashboardMruTitle",
  })
  vim.api.nvim_buf_set_extmark(bufnr, ns, title_line_idx, icon_start, {
    end_col = icon_start + #"󰠮 ",
    hl_group = "DashboardMruIcon",
  })

  for idx, entry in ipairs(entries) do
    local row = title_line_idx + idx
    local line_str = section_lines[idx + 2]
    local hash_start = title_col + 3
    local hash_end = hash_start + #"#"

    vim.api.nvim_buf_set_extmark(bufnr, ns, row, hash_start, {
      end_col = hash_end,
      hl_group = "DashboardFleetingHash",
    })
    vim.api.nvim_buf_set_extmark(bufnr, ns, row, hash_end, {
      end_col = #line_str,
      hl_group = "DashboardFiles",
    })

    local key = "n" .. idx
    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
      virt_text = { { key, "DashboardShortCut" } },
      virt_text_pos = "eol",
    })

    vim.keymap.set("n", key, function()
      zk.fleeting.open_file(entry.lnum)
    end, { buffer = bufnr, nowait = true, silent = true, desc = "Fleeting Note: " .. entry.text })
  end

  vim.keymap.set("n", "<CR>", function()
    local cur_row = vim.api.nvim_win_get_cursor(0)[1]
    local note_idx = cur_row - (title_line_idx + 1)
    if note_idx >= 1 and note_idx <= #entries then
      zk.fleeting.open_file(entries[note_idx].lnum)
      return
    end

    local text = vim.api.nvim_get_current_line()
    local scol = text:find("%p")
    local path = nil
    if scol then
      if text:sub(scol, scol + 1) ~= "~/" then
        local w = text:find("%w")
        scol = w and math.min(w, scol) or scol
      end
      text = text:sub(scol)
      path = text:sub(1, text:find("%w(%s+)$") or #text)
      path = vim.fs.normalize(path)
    end

    if not path then
      vim.cmd("enew")
    elseif vim.fn.isdirectory(path) == 1 then
      vim.cmd("lcd " .. path)
      require("snacks").picker.files({ cwd = path })
    else
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    end
  end, { buffer = bufnr, silent = true, nowait = true })

  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false
end

local function set_dashboard_highlights()
  vim.api.nvim_set_hl(0, "DashboardHeader", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "DashboardProjectTitle", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "DashboardProjectTitleIcon", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "DashboardProjectIcon", { link = "Directory", default = true })
  vim.api.nvim_set_hl(0, "DashboardMruTitle", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "DashboardMruIcon", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "DashboardFiles", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "DashboardShortCut", { link = "Keyword", default = true })
  vim.api.nvim_set_hl(0, "DashboardShortCutIcon", { link = "Function", default = true })
  vim.api.nvim_set_hl(0, "DashboardFooter", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "DashboardFleetingHash", { link = "DiagnosticSignError", default = true })
end

set_dashboard_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("dashboard-highlights", { clear = true }),
  callback = set_dashboard_highlights,
})

local dashboard_fleeting_group = vim.api.nvim_create_augroup("dashboard-fleeting-notes", { clear = true })

vim.api.nvim_create_autocmd("User", {
  pattern = { "DashboardLoaded", "ZkFleetingNotesUpdated" },
  group = dashboard_fleeting_group,
  callback = function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(b) and vim.bo[b].filetype == "dashboard" then
        render_fleeting_notes(b)
      end
    end
  end,
})

--- Fix dashboard stdin read issue.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Check if no stdin.
    if vim.fn.line2byte("$") ~= -1 then
      vim.g.read_from_stdin = 1
      return
    end

    local elapsed_ms = (vim.uv.hrtime() - start_time) / 1e6
    local stats = require("dashboard.utils").get_package_manager_stats()
    local v = vim.version()
    local quote = quotes[math.random(#quotes)]

    require("dashboard").setup({
      theme = "hyper",
      shortcut_type = "number",
      change_to_vcs_root = true,
      config = {
        header = header,
        packages = { enable = false },
        project = {
          enable = true,
          limit = 4,
          icon = "󰉋 ",
          label = " Recent Projects",
          action = function(path)
            require("snacks").picker.files({ cwd = path })
          end,
        },
        mru = {
          enable = true,
          limit = 6,
          icon = "󰋚 ",
          label = " Recent Files",
          cwd_only = false,
        },
        shortcut = {
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
          {
            icon = "󰠮 ",
            desc = "Notes ",
            group = "String",
            key = "z",
            action = "ZkNotes",
          },
          {
            icon = "󰒓 ",
            desc = "Config ",
            group = "Constant",
            key = "c",
            action = function()
              require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
            end,
          },
          {
            icon = "󰈆 ",
            desc = "Quit ",
            group = "DiagnosticError",
            key = "q",
            action = "qa",
          },
        },
        footer = {
          "",
          string.format(
            "⚡ Neovim v%d.%d.%d  •  󰏖 %d plugins  •  󱎫 %.1fms",
            v.major,
            v.minor,
            v.patch,
            stats.count,
            elapsed_ms
          ),
          "",
          "“" .. quote .. "”",
        },
      },
    })
  end,
})
