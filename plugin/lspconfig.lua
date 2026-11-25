vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

local function has_mix_exs(root)
  return root and vim.uv.fs_stat(vim.fs.joinpath(root, "mix.exs")) ~= nil
end

vim.lsp.config("expert", {
  cmd = { "expert", "--stdio" },
  filetypes = { "elixir", "eelixir", "heex", "surface" },
  root_dir = function(bufnr, on_dir)
    local root = require("project_root").resolve(bufnr)
    if has_mix_exs(root) then
      on_dir(root)
    end
  end,
})

vim.lsp.config("elixirls", {
  cmd = { "elixir-ls" },
  filetypes = { "elixir", "eelixir", "heex", "surface" },
  root_dir = function(bufnr, on_dir)
    local root = require("project_root").resolve(bufnr)
    if not has_mix_exs(root) then
      on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
    end
  end,
})

-- :help lspconfig-all
local servers = {
  "bashls",
  "ccls",
  "dartls",
  "elixirls",
  "expert",
  "fennel_ls",
  "gopls",
  "lua_ls",
  "nixd",
  "pyright",
  "ts_ls",
}

for _, server in ipairs(servers) do
  vim.lsp.enable(server)
end
