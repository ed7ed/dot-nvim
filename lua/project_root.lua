local M = {}

local home = vim.uv.os_homedir()

M.patterns = function()
  return {
    ".bzr",
    ".cache",
    ".ccls-cache",
    ".clj-kondo",
    ".cpcache",
    ".dart_tool",
    ".elixir_ls",
    ".fvm",
    ".git",
    ".hg",
    ".lsp",
    ".svn",
    "CVS",
    "MCVS",
    "Makefile",
    "RCS",
    "SCCS",
    "_build",
    "_darcs",
    "deps",
    "dist",
    "elm-stuff",
    "eln-cache",
    "elpaca",
    "flsproject.fnl",
    "go.mod",
    "io.erl",
    "mix.exs",
    "node_modules",
    "package.json",
    "pubspec.yaml",
    "vendor",
    "venv",
  }
end

M.resolve = function(buf)
  if vim.b[buf].project_root_cache then
    return vim.b[buf].project_root_cache
  end

  local root = vim.fs.root(buf, { M.patterns() }) or ""
  local cwd = vim.fn.getcwd()

  if (cwd ~= root) and vim.startswith(cwd, root) then
    root = cwd
  end

  if root == home then
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      if client.root_dir and client.root_dir ~= home then
        root = client.root_dir
        break
      end
    end
  end

  return root ~= "" and root or false
end

return M
