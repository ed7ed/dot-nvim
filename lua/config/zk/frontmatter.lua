local M = {}

local UPDATED_FORMAT = vim.env.ZK_DATE_FORMAT or "%Y-%m-%d %a"
local UPDATED_KEYS = { updated = true, updated_at = true }

---@param lines string[]
---@return integer? idx, string? key, string? value
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
    if key and UPDATED_KEYS[key] then
      return i, key, value
    end
  end

  return nil
end

---Returns:
---  `string[]` - file lines from git HEAD
---  `false`    - inside a git worktree, but file is not in HEAD yet
---  `nil`      - not inside a git worktree
---@param path string
---@return string[]|false|nil
local function git_head_lines(path)
  local dir, name = vim.fs.dirname(path), vim.fs.basename(path)
  if vim.system({ "git", "-C", dir, "rev-parse", "--is-inside-work-tree" }):wait().code ~= 0 then
    return nil
  end

  local res = vim.system({ "git", "-C", dir, "show", "HEAD:./" .. name }, { text = true }):wait()
  if res.code ~= 0 then
    return false
  end

  local stdout = (res.stdout or ""):gsub("\r", "")
  local lines = vim.split(stdout, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end

  return lines
end

---@param lines string[]
---@param idx? integer
---@return string[]
local function without_line(lines, idx)
  if not idx then
    return lines
  end

  local copy = vim.list_slice(lines, 1, idx - 1)
  vim.list_extend(copy, lines, idx + 1)
  return copy
end

---@param buf integer
---@param path string
local function update_buffer(buf, path)
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

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("zk_updated_frontmatter", { clear = true }),
    pattern = "*.md",
    desc = "Update zk note `updated` frontmatter field",
    callback = function(args)
      if not vim.bo[args.buf].modified then
        return
      end

      local path = vim.api.nvim_buf_get_name(args.buf)
      if path == "" or not vim.fs.root(path, ".zk") then
        return
      end

      update_buffer(args.buf, path)
    end,
  })
end

return M
