require("nvim-treesitter").install({
  "bash",
  "c",
  "css",
  "dart",
  "diff",
  "eex",
  "elixir",
  "erlang",
  "go",
  "gomod",
  "gotmpl",
  "heex",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "just",
  "lua",
  "luadoc",
  "luap",
  "make",
  "markdown",
  "markdown_inline",
  "mermaid",
  "nix",
  "printf",
  "python",
  "query",
  "regex",
  "scss",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
  pattern = "*",
  callback = function()
    local ok = pcall(vim.treesitter.start)
    if ok then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
