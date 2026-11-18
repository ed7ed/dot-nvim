vim.o.autoindent = true -- indent matches previous line
vim.o.autoread = true -- reload file if changed outside nvim
vim.o.backup = false -- no backup before overwriting
vim.o.clipboard = "unnamed,unnamedplus" -- sync with system clipboard
vim.o.completeopt = "menu,menuone,noselect" -- completion menu behavior
vim.o.cursorline = true -- highlight current line
vim.o.expandtab = true -- spaces instead of tabs
vim.o.fillchars = "fold:." -- fill fold lines with dots
vim.o.foldenable = true -- enable folding
vim.o.foldtext = "" -- colorized folds (nvim >= 0.10)
vim.o.formatoptions = vim.o.formatoptions:gsub("t", ""):gsub("c", "") -- no break lines
vim.o.grepprg = "rg --hidden --vimgrep --smart-case --" -- use ripgrep for :grep
vim.o.ignorecase = true -- case-insensitive search
vim.o.laststatus = 3 -- single global statusline
vim.o.linebreak = true -- wrap at word boundary
vim.o.list = true -- show listchars
vim.o.listchars = "tab:  ,nbsp:+,trail:·,extends:→,precedes:←" -- whitespace indicators
vim.o.number = true -- show line numbers
vim.o.pumheight = 15 -- max completion menu height
vim.o.shiftround = true -- round indent to shiftwidth
vim.o.shiftwidth = 4 -- indent step = 4 spaces
vim.o.showmode = false -- mode shown in statusline instead
vim.o.showtabline = 0 -- never show tabline
vim.o.signcolumn = "yes" -- always show sign column
vim.o.smartcase = true -- case-sensitive if uppercase used
vim.o.softtabstop = 4 -- <Tab> inserts 4 spaces
vim.o.swapfile = false -- no swapfile
vim.o.tabstop = 4 -- visual width of tab char
vim.o.termguicolors = true -- 24-bit RGB colors
vim.o.textwidth = 80
vim.o.spelllang = "en,uk" -- use English and Ukrainian for spell checking
vim.o.undofile = true -- persistent undo history
vim.o.updatetime = 500 -- ms before CursorHold / highlights
vim.o.virtualedit = "onemore" -- cursor past end of line
vim.o.wrap = true -- soft-wrap long lines
vim.o.writebackup = false -- no backup while writing

vim.opt.guicursor:append({ "t:blinkon0" }) -- no terminal cursor blink
