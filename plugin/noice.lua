require("noice").setup({
  presets = { lsp_doc_border = true },
  cmdline = {
    format = {
      search_down = { view = "cmdline" },
      search_up = { view = "cmdline" },
    },
  },
  messages = {
    view_search = false, -- disable `search_count` virtualtext
  },
})
