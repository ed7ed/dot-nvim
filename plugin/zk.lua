---@type table<string, any>
local zk = require("zk")

---@type table<string, any>
local ui = require("zk.ui")

zk.setup({ picker = "select" })

----- Use recent used history -----

local MAX_HISTORY = 7

local function get_notebook_dir()
  local dir = vim.env.ZK_NOTEBOOK_DIR
  if not dir or dir == "" then
    return nil
  end
  local stat = vim.uv.fs_stat(dir)
  if not stat or stat.type ~= "directory" then
    return nil
  end
  return dir
end

local function get_history_path()
  local dir = get_notebook_dir()
  if not dir then
    return nil
  end
  return vim.fs.joinpath(dir, ".zk", "history")
end

local function read_history()
  local history_path = get_history_path()
  if not history_path or not vim.uv.fs_stat(history_path) then
    return {}
  end

  local history = {}
  local seen = {}
  for _, line in ipairs(vim.fn.readfile(history_path)) do
    local entry = vim.trim(line)
    if entry ~= "" and not seen[entry] then
      seen[entry] = true
      table.insert(history, entry)
      if #history >= MAX_HISTORY then
        break
      end
    end
  end

  return history
end

local function record_history(abs_path)
  local history_path = get_history_path()
  if not history_path then
    return
  end

  local history = { abs_path }
  for _, entry in ipairs(read_history()) do
    if entry ~= abs_path then
      table.insert(history, entry)
      if #history >= MAX_HISTORY then
        break
      end
    end
  end

  vim.fn.mkdir(vim.fs.dirname(history_path), "p")
  vim.fn.writefile(history, history_path)
end

local function sort_notes_by_history(notes)
  local history = read_history()
  if #history == 0 then
    return notes
  end

  local rank = {}
  for idx, path in ipairs(history) do
    rank[path] = idx
  end

  local recent = {}
  local rest = {}

  for _, note in ipairs(notes) do
    local r = rank[note.absPath] or rank[note.path]
    if r then
      table.insert(recent, { rank = r, note = note })
    else
      table.insert(rest, note)
    end
  end

  table.sort(recent, function(a, b)
    return a.rank < b.rank
  end)

  local sorted = {}
  for _, item in ipairs(recent) do
    table.insert(sorted, item.note)
  end
  vim.list_extend(sorted, rest)

  return sorted
end

local orig_pick_notes = ui.pick_notes
ui.pick_notes = function(notes, options, cb)
  if not options or options.title == nil or options.title == "Zk Notes" then
    notes = sort_notes_by_history(notes)
  end
  return orig_pick_notes(notes, options, cb)
end

zk.edit = function(options, picker_options)
  local title = picker_options and picker_options.title or ""
  local should_record = title == "Zk Notes" or vim.startswith(title, "Zk Notes for tag(s)")

  zk.pick_notes(options, picker_options, function(notes)
    if picker_options and picker_options.multi_select == false then
      notes = { notes }
    end
    for _, note in ipairs(notes) do
      if should_record then
        record_history(note.absPath)
      end
      vim.cmd("e " .. vim.fn.fnameescape(note.absPath))
    end
  end)
end

----- Use recent used history ENDS HERE -----

----- Update yaml frontmatter updated_at -----

local UPDATED_FORMAT = vim.env.ZK_DATE_FORMAT or "%Y-%m-%d %a"

local function find_updated(lines)
  if lines[1] ~= "---" then
    return nil
  end
  for i = 2, #lines do
    local line = lines[i]
    if line == "---" then
      return nil
    end
    local key, value = line:match("^(updated[_%w]*):%s*(.-)%s*$")
    if key == "updated" or key == "updated_at" then
      return i, key, value
    end
  end
end

local function git_head_lines(path)
  local dir, name = vim.fs.dirname(path), vim.fs.basename(path)
  if vim.system({ "git", "-C", dir, "rev-parse", "--is-inside-work-tree" }):wait().code ~= 0 then
    return nil
  end
  local res = vim.system({ "git", "-C", dir, "show", "HEAD:./" .. name }, { text = true }):wait()
  if res.code ~= 0 then
    return false
  end
  local lines = vim.split((res.stdout:gsub("\r", "")), "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function without_line(lines, idx)
  if not idx then
    return lines
  end
  local copy = vim.list_slice(lines, 1, idx - 1)
  vim.list_extend(copy, lines, idx + 1)
  return copy
end

local function update_frontmatter(buf, path)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local idx, key, value = find_updated(lines)
  if not idx then
    return
  end

  local head = git_head_lines(path)
  if head == nil then
    return
  end

  local new_value = os.date(UPDATED_FORMAT)
  if head then
    local head_idx, _, head_value = find_updated(head)
    if vim.deep_equal(without_line(lines, idx), without_line(head, head_idx)) then
      if not head_value then
        return
      end
      new_value = head_value
    end
  end

  if value ~= new_value then
    pcall(vim.cmd.undojoin)
    vim.api.nvim_buf_set_lines(buf, idx - 1, idx, false, { key .. ": " .. new_value })
  end
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("zk_updated_frontmatter", { clear = true }),
  pattern = "*.md",
  desc = "Update zk note `updated` frontmatter field",
  callback = function(args)
    if not vim.bo[args.buf].modified then
      return
    end
    local path = vim.api.nvim_buf_get_name(args.buf)
    if not vim.fs.root(path, ".zk") then
      return
    end
    update_frontmatter(args.buf, path)
  end,
})

----- Update yaml frontmatter updated_at ENDS HERE -----

----- Fleeting notes -----

local FLEETING_NOTES_FILENAME = "m076.md"

local function get_fleeting_notes_path()
  local dir = get_notebook_dir()
  if not dir then
    return nil
  end
  local path = vim.fs.joinpath(dir, FLEETING_NOTES_FILENAME)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return nil
  end
  return path
end

local function notify_missing_fleeting_notes()
  vim.notify(
    string.format("Fleeting notes unavailable: check ZK_NOTEBOOK_DIR and %s", FLEETING_NOTES_FILENAME),
    vim.log.levels.WARN
  )
end

local function get_fleeting_headers(limit)
  local fleeting_notes_path = get_fleeting_notes_path()
  if not fleeting_notes_path then
    return {}
  end

  limit = limit or 5
  local ok, lines = pcall(vim.fn.readfile, fleeting_notes_path)
  if not ok then
    return {}
  end

  local headers = {}
  local in_codeblock = false
  local in_frontmatter = false

  for i, line in ipairs(lines) do
    if i == 1 and line == "---" then
      in_frontmatter = true
    elseif in_frontmatter then
      if line == "---" then
        in_frontmatter = false
      end
    elseif line:match("^```") then
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

  local recent = {}
  for i = #headers, math.max(1, #headers - limit + 1), -1 do
    table.insert(recent, headers[i])
  end
  return recent
end

local function write_fleeting_snippet(snippet_lines, range)
  local fleeting_notes_path = get_fleeting_notes_path()
  if not fleeting_notes_path then
    notify_missing_fleeting_notes()
    return nil
  end

  local ok, existing = pcall(vim.fn.readfile, fleeting_notes_path)
  if not ok then
    notify_missing_fleeting_notes()
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

  vim.fn.writefile(new_lines, fleeting_notes_path)
  vim.cmd("checktime")
  vim.api.nvim_exec_autocmds("User", { pattern = "ZkFleetingNotesUpdated", modeline = false })

  return { new_start, new_end }
end

local function open_new_fleeting_note()
  if not get_fleeting_notes_path() then
    notify_missing_fleeting_notes()
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

  local width, height = 80, 17
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = string.format(" 󰠮 New Fleeting Note (%s) ", FLEETING_NOTES_FILENAME),
    title_pos = "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].foldenable = false

  local saved_range = nil

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      while #lines > 1 and lines[#lines] == "" do
        table.remove(lines)
      end

      if not lines[1]:match("^#%s+") then
        lines[1] = "# " .. lines[1]:gsub("^#+%s*", "")
        vim.api.nvim_buf_set_lines(buf, 0, 1, false, { lines[1] })
      end

      local next_range = write_fleeting_snippet(lines, saved_range)
      if not next_range then
        return
      end
      saved_range = next_range
      vim.bo[buf].modified = false
      vim.notify(string.format("Saved to fleeting notes (%s)", FLEETING_NOTES_FILENAME), vim.log.levels.INFO)
    end,
  })

  local function close_popup()
    vim.api.nvim_win_close(win, true)
    if not saved_range then
      vim.notify("Fleeting note canceled", vim.log.levels.INFO)
    end
  end

  vim.keymap.set("n", "q", close_popup, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<c-c>", close_popup, { buffer = buf, nowait = true, silent = true })

  vim.api.nvim_win_set_cursor(win, { 1, 2 })
end

zk.fleeting = {
  path = get_fleeting_notes_path(),
  name = FLEETING_NOTES_FILENAME,
  is_available = function()
    return get_fleeting_notes_path() ~= nil
  end,
  get_headers = get_fleeting_headers,
  open_new = open_new_fleeting_note,
  open_file = function(lnum)
    local fleeting_notes_path = get_fleeting_notes_path()
    if not fleeting_notes_path then
      notify_missing_fleeting_notes()
      return
    end
    if lnum then
      vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(fleeting_notes_path))
      vim.cmd("normal! zz")
    else
      vim.cmd("edit " .. vim.fn.fnameescape(fleeting_notes_path))
    end
  end,
}

----- Fleeting notes ENDS HERE -----
