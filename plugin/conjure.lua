vim.g["conjure#log#treesitter"] = false
vim.g["conjure#mapping#doc_word"] = false

-- Lazy elixir integration. Do not auto run repl on visiting a buffer.
vim.g["conjure#filetype#elixir"] = false

vim.api.nvim_create_user_command("ConjureAttach", function()
  vim.g["conjure#filetype#elixir"] = "conjure.client.elixir.stdio"
  vim.cmd("doautocmd FileType " .. vim.bo.filetype)
end, { desc = "Manually attach Conjure and generate its commands" })

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "conjure-log-*",
  callback = function()
    vim.diagnostic.enable(false, { bufnr = 0 })
  end,
})
