require("toggleterm").setup({
  highlights = {
    FloatBorder = { link = "Function" },
    Normal = { link = "Normal" },
    NormalFloat = { link = "Normal" },
  },
  shell = (function()
    vim.fn.system("which zsh")
    if vim.v.shell_error == 0 then
      return "zsh"
    end
    return "bash"
  end)(),
  size = 15,
})
