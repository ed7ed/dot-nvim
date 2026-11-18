require("nvim-autopairs").setup({
  check_ts = true, -- use treesitter to avoid pairing inside strings/comments
  disable_in_macro = true, -- no pairs while recording a macro
  disable_in_replace_mode = true, -- no pairs in replace mode (r/R)
  enable_check_bracket_line = true, -- don't close if closing pair already on same line
})
