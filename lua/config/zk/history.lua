local notebook = require("config.zk.notebook")

local M = {}

local MAX_HISTORY = 7
local HISTORY_REL_PATH = { ".zk", "history" }

local patched = false

local function get_history_path()
  return notebook.path(unpack(HISTORY_REL_PATH))
end

local function should_sort(title)
  return title == nil or title == "Zk Notes"
end

local function should_record(title)
  return title == "Zk Notes" or (type(title) == "string" and vim.startswith(title, "Zk Notes for tag(s)"))
end

function M.read()
  local path = get_history_path()
  if not path or not vim.uv.fs_stat(path) then
    return {}
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end

  local history = {}
  local seen = {}

  for _, line in ipairs(lines) do
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

function M.record(abs_path)
  if not abs_path or abs_path == "" then
    return
  end

  local path = get_history_path()
  if not path then
    return
  end

  local history = { abs_path }
  for _, entry in ipairs(M.read()) do
    if entry ~= abs_path then
      table.insert(history, entry)
      if #history >= MAX_HISTORY then
        break
      end
    end
  end

  vim.fn.mkdir(vim.fs.dirname(path), "p")
  pcall(vim.fn.writefile, history, path)
end

function M.sort_notes(notes)
  local history = M.read()
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

function M.setup(zk)
  if patched then
    return
  end
  patched = true

  local ui = require("zk.ui")
  local orig_pick_notes = ui.pick_notes

  ui.pick_notes = function(notes, options, cb)
    if should_sort(options and options.title) then
      notes = M.sort_notes(notes)
    end
    return orig_pick_notes(notes, options, cb)
  end

  zk.edit = function(options, picker_options)
    local record = should_record(picker_options and picker_options.title)

    zk.pick_notes(options, picker_options, function(notes)
      if picker_options and picker_options.multi_select == false then
        notes = { notes }
      end

      for _, note in ipairs(notes) do
        if record then
          M.record(note.absPath)
        end
        vim.cmd.edit(vim.fn.fnameescape(note.absPath))
      end
    end)
  end
end

return M
