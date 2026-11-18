require("conform").setup({
  default_format_opts = {
    timeout_ms = 3000,
    async = false,
    quiet = false,
    lsp_format = "fallback",
  },

  formatters_by_ft = {
    go = { "goimports", "gopls" },
    javascript = { "prettier" },
    json = { "prettier" },
    lua = { "stylua" },
    make = { "bake" },
    nix = { "nixfmt" },
    sh = { "shfmt" },
  },

  formatters = {
    injected = { options = { ignore_errors = true } },
  },

  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end

    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match("/node_modules/") then
      return
    end

    return { lsp_format = "fallback" }
  end,
})
