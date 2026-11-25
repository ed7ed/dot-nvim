require("conform").setup({
  default_format_opts = {
    timeout_ms = 3000,
    async = false,
    quiet = false,
    lsp_format = "fallback",
  },

  formatters_by_ft = {
    fennel = { "fnlfmt" },
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
    shfmt = {
      append_args = { "-i", "2" },
    },
  },

  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end

    -- Do not autosave packages in node_modules.
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match("/node_modules/") then
      return
    end

    return { lsp_format = "fallback" }
  end,
})
