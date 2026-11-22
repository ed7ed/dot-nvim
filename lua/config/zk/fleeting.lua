local notebook = require("config.zk.notebook")

local FILENAME = "m076.md"
local DEFAULT_LIMIT = 5
local POPUP_WIDTH = 80
local POPUP_HEIGHT = 17
local UPDATED_EVENT = "ZkFleetingNotesUpdated"

---@class ZkFleetingHeader
---@field lnum integer
---@field level integer
---@field text string

local M = {
  name = FILENAME,
  updated_event = UPDATED_EVENT,
}

---@return string?
function M.get_path()
  return notebook.file_path(FILENAME)
end

---@return boolean
function M.is_available()
  return M.get_path() ~= nil
end

local function notify_missing()
  vim.notify(string.format("Fleeting notes unavailable: check ZK_NOTEBOOK_DIR and %s", FILENAME), vim.log.levels.WARN)
end

local function emit_updated()
  vim.api.nvim_exec_autocmds("User", { pattern = UPDATED_EVENT, modeline = false })
end

---@param lines string[]
---@return ZkFleetingHeader[]
local function parse_headers(lines)
  local headers = {}
  local in_frontmatter = false
  local in_codeblock = false

  for i, line in ipairs(lines) do
    if i == 1 and line == "---" then
      in_frontmatter = true
    elseif in_frontmatter then
      if line == "---" then
        in_frontmatter = false
      end
    elseif line:match("^```") or line:match("^~~~") then
      in_codeblock = not in_codeblock
    elseif not in_codeblock then
      local hashes, text = line:match("^(#+)%s*(.+)$")
      if hashes and text then
        table.insert(headers, {
          lnum = i,
          level = #hashes,
          text = vim.trim(text),
        })
      end
    end
  end

  return headers
end

---@param limit? integer
---@return ZkFleetingHeader[]
function M.get_headers(limit)
  local path = M.get_path()
  if not path then
    return {}
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end

  local headers = parse_headers(lines)
  local count = limit or DEFAULT_LIMIT
  local recent = {}

  for i = #headers, math.max(1, #headers - count + 1), -1 do
    table.insert(recent, headers[i])
  end

  return recent
end

---@param snippet_lines string[]
---@param range? integer[]
---@return integer[]?
local function write_snippet(snippet_lines, range)
  local path = M.get_path()
  if not path then
    notify_missing()
    return nil
  end

  local ok, existing = pcall(vim.fn.readfile, path)
  if not ok then
    notify_missing()
    return nil
  end

  local start_idx = range and range[1] or (#existing + 1)
  local end_idx = range and range[2] or #existing

  local before = vim.list_slice(existing, 1, start_idx - 1)
  local after = vim.list_slice(existing, end_idx + 1, #existing)

  local block = (#before > 0 and before[#before] ~= "") and { "" } or {}
  vim.list_extend(block, snippet_lines)

  local new_lines = {}
  vim.list_extend(new_lines, before)
  local new_start = #new_lines + 1
  vim.list_extend(new_lines, block)
  local new_end = #new_lines
  vim.list_extend(new_lines, after)

  vim.fn.writefile(new_lines, path)
  vim.cmd("checktime")
  emit_updated()

  return { new_start, new_end }
end

---@param buf integer
---@return string[]
local function normalize_snippet(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while #lines > 1 and lines[#lines] == "" do
    table.remove(lines)
  end

  if not lines[1]:match("^#%s+") then
    lines[1] = "# " .. lines[1]:gsub("^#+%s*", "")
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { lines[1] })
  end

  return lines
end

---@param buf integer
---@return integer win
local function open_popup_window(buf)
  local width = math.max(20, math.min(POPUP_WIDTH, vim.o.columns - 4))
  local height = math.max(6, math.min(POPUP_HEIGHT, vim.o.lines - 4))
  local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" 󰠮 New Fleeting Note (%s) ", FILENAME),
    title_pos = "center",
    footer = " :w save · <esc> close · <c-c> close ",
    footer_pos = "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].foldenable = false

  return win
end

function M.open_new()
  if not M.is_available() then
    notify_missing()
    return
  end

  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, "fleeting-note://" .. tostring(vim.uv.hrtime()))

  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.b[buf].disable_autoformat = true

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# " })
  vim.bo[buf].modified = false

  local win = open_popup_window(buf)
  local saved_range = nil

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local lines = normalize_snippet(buf)
      local next_range = write_snippet(lines, saved_range)
      if not next_range then
        return
      end

      saved_range = next_range
      vim.bo[buf].modified = false
      vim.notify(string.format("Saved to fleeting notes (%s)", FILENAME), vim.log.levels.INFO)
    end,
  })

  local function close_popup()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if not saved_range then
      vim.notify("Fleeting note canceled", vim.log.levels.INFO)
    end
  end

  vim.keymap.set("n", "<esc>", close_popup, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<c-c>", close_popup, { buffer = buf, nowait = true, silent = true })

  vim.api.nvim_win_set_cursor(win, { 1, 2 })
end

---@param lnum? integer
function M.open_file(lnum)
  local path = M.get_path()
  if not path then
    notify_missing()
    return
  end

  if lnum then
    vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(path))
    vim.cmd("normal! zz")
  else
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("zk_fleeting_notes_sync", { clear = true }),
    pattern = "*" .. FILENAME,
    desc = "Notify listeners when the fleeting notes file is saved",
    callback = function(args)
      local path = M.get_path()
      if not path then
        return
      end
      local buf_path = vim.api.nvim_buf_get_name(args.buf)
      if buf_path ~= "" and vim.fs.normalize(buf_path) == vim.fs.normalize(path) then
        emit_updated()
      end
    end,
  })
end

return setmetatable(M, {
  __index = function(_, key)
    if key == "path" then
      return M.get_path()
    end
  end,
})
