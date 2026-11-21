local content = require("config.dashboard.content")
local fleeting = require("config.zk.fleeting")

local M = {}

local NS = vim.api.nvim_create_namespace("dashboard_fleeting")
local ITEM_INDENT = 3
local EMPTY_PLACEHOLDER = "No fleeting notes yet"

local buffer_state = {}

local function truncate(text, max_width)
  if vim.api.nvim_strwidth(text) <= max_width then
    return text
  end

  local chars = vim.fn.strchars(text)
  local target = math.max(1, max_width - 1)
  local lo, hi = 0, chars

  while lo < hi do
    local mid = math.ceil((lo + hi) / 2)
    if vim.api.nvim_strwidth(vim.fn.strcharpart(text, 0, mid)) <= target then
      lo = mid
    else
      hi = mid - 1
    end
  end

  return vim.fn.strcharpart(text, 0, lo) .. "…"
end

local function pad_to_width(text, target_width)
  local cur = vim.api.nvim_strwidth(text)
  return cur < target_width and (text .. (" "):rep(target_width - cur)) or text
end

local function find_layout(buf_lines, section_title)
  local mru_anchor = content.sections.mru.icon .. content.sections.mru.label
  local mru_row, title_col, block_width = 1, 0, 50
  local existing_title_row = nil

  for idx, line in ipairs(buf_lines) do
    local mru_start = line:find(mru_anchor, 1, true)
    if mru_start then
      mru_row = idx
      title_col = mru_start - 1
      block_width = vim.api.nvim_strwidth(line) - title_col
    end

    if line:find(section_title, 1, true) then
      existing_title_row = idx
    end
  end

  local footer_row = #buf_lines + 1
  for idx = mru_row + 1, #buf_lines do
    if buf_lines[idx]:find(content.sections.footer_marker, 1, true) then
      footer_row = idx - 1
      break
    end
  end

  return {
    title_col = title_col,
    block_width = block_width,
    existing_title_row = existing_title_row,
    footer_row = footer_row,
  }
end

local function build_section_lines(entries, section_title, layout)
  local target_width = layout.title_col + layout.block_width
  local title_prefix = (" "):rep(layout.title_col)
  local item_prefix = (" "):rep(layout.title_col + ITEM_INDENT)
  local max_text_width = math.max(layout.block_width - ITEM_INDENT - 4, 20)

  local lines = {
    "",
    pad_to_width(title_prefix .. section_title, target_width),
  }

  if #entries == 0 then
    table.insert(lines, pad_to_width(item_prefix .. EMPTY_PLACEHOLDER, target_width))
    return lines
  end

  for _, entry in ipairs(entries) do
    local label = truncate(entry.text, max_text_width)
    table.insert(lines, pad_to_width(item_prefix .. "# " .. label, target_width))
  end

  return lines
end

local function apply_highlights(bufnr, entries, section_lines, title_row, title_col)
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)

  local title_line = section_lines[2]
  local icon_end = title_col + #content.sections.fleeting.icon

  vim.api.nvim_buf_set_extmark(bufnr, NS, title_row, title_col, {
    end_col = icon_end,
    hl_group = "DashboardMruIcon",
  })
  vim.api.nvim_buf_set_extmark(bufnr, NS, title_row, icon_end, {
    end_col = #title_line,
    hl_group = "DashboardMruTitle",
  })

  if #entries == 0 then
    local empty_line = section_lines[3]
    vim.api.nvim_buf_set_extmark(bufnr, NS, title_row + 1, title_col + ITEM_INDENT, {
      end_col = #empty_line,
      hl_group = "DashboardFleetingEmpty",
    })
    return
  end

  local hash_start = title_col + ITEM_INDENT
  local hash_end = hash_start + #"#"

  for idx = 1, #entries do
    local row = title_row + idx
    local line_str = section_lines[idx + 2]

    vim.api.nvim_buf_set_extmark(bufnr, NS, row, hash_start, {
      end_col = hash_end,
      hl_group = "DashboardFleetingHash",
    })
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, hash_end, {
      end_col = #line_str,
      hl_group = "DashboardFiles",
    })
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
      virt_text = { { "n" .. idx, "DashboardShortCut" } },
      virt_text_pos = "eol",
    })
  end
end

local function ensure_buffer_state(bufnr)
  local state = buffer_state[bufnr]
  if state then
    return state
  end

  local default_cr = nil
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
    if map.lhs:upper() == "<CR>" and type(map.callback) == "function" then
      default_cr = map.callback
      break
    end
  end

  state = {
    default_cr = default_cr,
    bound_keys = {},
  }
  buffer_state[bufnr] = state

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    once = true,
    callback = function()
      buffer_state[bufnr] = nil
    end,
  })

  return state
end

local function bind_keymaps(bufnr, entries, title_row)
  local state = ensure_buffer_state(bufnr)

  for _, key in ipairs(state.bound_keys) do
    pcall(vim.keymap.del, "n", key, { buffer = bufnr })
  end
  state.bound_keys = {}

  for idx, entry in ipairs(entries) do
    local key = "n" .. idx
    table.insert(state.bound_keys, key)
    vim.keymap.set("n", key, function()
      fleeting.open_file(entry.lnum)
    end, { buffer = bufnr, nowait = true, silent = true, desc = "Fleeting Note: " .. entry.text })
  end

  vim.keymap.set("n", "<CR>", function()
    local cur_row = vim.api.nvim_win_get_cursor(0)[1]
    local note_idx = cur_row - (title_row + 1)
    if note_idx >= 1 and note_idx <= #entries then
      fleeting.open_file(entries[note_idx].lnum)
      return
    end

    if state.default_cr then
      state.default_cr()
    end
  end, { buffer = bufnr, silent = true, nowait = true })
end

function M.render(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not fleeting.is_available() then
    return
  end

  local cfg = content.sections.fleeting
  local entries = fleeting.get_headers(cfg.limit)
  local section_title = string.format("%s%s (%s)", cfg.icon, cfg.label, fleeting.name)

  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local layout = find_layout(buf_lines, section_title)
  local section_lines = build_section_lines(entries, section_title, layout)

  local insert_start = layout.existing_title_row and (layout.existing_title_row - 2) or (layout.footer_row - 1)
  local insert_end = layout.footer_row - 1
  local title_row = insert_start + 1

  vim.bo[bufnr].modifiable = true
  local ok, err = pcall(function()
    vim.api.nvim_buf_set_lines(bufnr, insert_start, insert_end, false, section_lines)
    apply_highlights(bufnr, entries, section_lines, title_row, layout.title_col)
    bind_keymaps(bufnr, entries, title_row)
  end)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false

  if not ok then
    vim.notify("Dashboard fleeting notes render failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.render_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "dashboard" then
      M.render(bufnr)
    end
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("dashboard_fleeting_notes", { clear = true }),
    pattern = { "DashboardLoaded", fleeting.updated_event },
    desc = "Render fleeting notes section on dashboard",
    callback = M.render_all,
  })
end

return M
