require("smart-splits").setup({
  mux = {
    backend = "smart-splits-backend-tmux",
    warn_if_unusable = false,
  },
})
