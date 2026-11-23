local exclude_search_patterns = {
  ".cache",
  ".ccls-cache",
  ".clj-kondo",
  ".cpcache",
  ".dart_tool",
  ".elixir_ls",
  ".expert",
  ".lsp",
  "_build",
  "build",
  "deps",
  "dist",
  "elm-stuff",
  "eln-cache",
  "elpaca",
  "node_modules",
  "vendor",
  "venv",
}

require("snacks").setup({
  picker = {
    layouts = {
      default = {
        layout = {
          width = 0.95,
          height = 0.9,
        },
      },
    },
    ui_select = true,
    exclude = exclude_search_patterns,
    hidden = true,
    ignored = true,
    matcher = {
      ignorecase = true,
      smartcase = false,
    },
    sources = {
      files = {
        hidden = true,
        ignored = true,
      },
      buffers = {
        current = false, -- remove current buffer from the buffer list.
      },
      grep = {
        exclude = exclude_search_patterns,
        args = { "--ignore-case" },
      },
      grep_buffers = {
        args = { "--ignore-case" },
      },
      grep_word = {
        args = { "--word-regexp", "--ignore-case" },
      },
    },
    win = {
      input = {
        keys = {
          ["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
          ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
          ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
          ["<f1>"] = { "toggle_help_input", mode = { "i", "n" } },
          ["<f2>"] = { "toggle_maximize", mode = { "i", "n" } },
          ["<c-c>"] = { "close", mode = { "i", "n" } },
          ["<esc>"] = { "close", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["<a-p>"] = "toggle_preview",
          ["<c-d>"] = "preview_scroll_down",
          ["<c-u>"] = "preview_scroll_up",
          ["<f1>"] = "toggle_help_list",
          ["<f2>"] = "toggle_maximize",
          ["<c-c>"] = "close",
          ["<esc>"] = "close",
        },
      },
    },
  },
})
