require("blink.cmp").setup({
  keymap = {
    preset = "none",
    ["<c-d>"] = { "scroll_documentation_up", "fallback" },
    ["<c-u>"] = { "scroll_documentation_down", "fallback" },
    ["<c-f>"] = { "select_and_accept", "fallback" },
    ["<c-n>"] = { "select_next", "fallback" },
    ["<c-p>"] = { "select_prev", "fallback" },
    ["<c-q>"] = { "hide", "fallback" },
    ["<c-space>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
    ["<cr>"] = { "select_and_accept", "fallback" },
    ["<s-tab>"] = { "snippet_backward", "fallback" },
    ["<tab>"] = { "snippet_forward", "fallback" },
  },

  appearance = { nerd_font_variant = "mono" },
  cmdline = { enabled = false },
  fuzzy = { implementation = "lua" },
  snippets = { preset = "luasnip" },
  sources = {
    default = { "lsp", "path", "snippets", "buffer", "tmux" },
    providers = {
      lsp = {
        name = "lsp",
        enabled = true,
        module = "blink.cmp.sources.lsp",
        score_offset = 100,
      },
      path = {
        score_offset = 60,
      },
      snippets = {
        score_offset = 50,
      },
      tmux = {
        name = "tmux",
        module = "blink-cmp-tmux",
        score_offset = -3,
        opts = {
          panes = "all",
        },
      },
    },
  },

  completion = {
    menu = {
      border = "rounded",
    },
    documentation = {
      window = {
        border = "rounded",
      },
    },
  },
})
