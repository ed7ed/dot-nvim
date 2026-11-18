local M = {}

local RULES = {
  {
    pattern = "(.*)/test/(.*)_test%.exs$",
    target = "%1/lib/%2.ex",
  },
  {
    pattern = "(.*)/lib/(.*)%.ex$",
    target = "%1/test/%2_test.exs",
  },
}

function M.get_counterpart_path(path)
  for _, rule in ipairs(RULES) do
    local new_path, count = path:gsub(rule.pattern, rule.target)
    if count > 0 then
      return new_path
    end
  end
  return nil
end

local function ensure_file_ready(path)
  if vim.uv.fs_stat(path) then
    return true
  end

  local prompt = string.format("File does not exist. Create it?\n%s", path)
  local ok, choice = pcall(vim.fn.confirm, prompt, "&Yes\n&No", 2)
  if not ok or choice ~= 1 then
    return false
  end

  local dir = vim.fs.dirname(path)
  vim.fn.mkdir(dir, "p")
  return true
end

function M.switch_source_test()
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == "" then
    vim.notify("Buffer has no file name", vim.log.levels.ERROR)
    return
  end

  local target_path = M.get_counterpart_path(file_path)
  if not target_path then
    vim.notify("Could not determine counterpart Elixir file", vim.log.levels.WARN)
    return
  end

  if ensure_file_ready(target_path) then
    vim.cmd.edit(vim.fn.fnameescape(target_path))
  end
end

return M
