local M = {}

function M.dir()
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

function M.path(...)
  local dir = M.dir()
  if not dir then
    return nil
  end
  return vim.fs.joinpath(dir, ...)
end

function M.file_path(...)
  local path = M.path(...)
  if not path then
    return nil
  end

  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return nil
  end

  return path
end

return M
