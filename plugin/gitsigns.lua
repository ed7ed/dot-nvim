require("gitsigns").setup({
  on_attach = function(bufnr)
    -- Avoid gpg decrypted buffers.
    if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":e") == "gpg" then
      return false
    end
    return true
  end,
})
