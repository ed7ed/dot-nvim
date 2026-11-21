local set = vim.keymap.set

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- "," as a second leader.
set({ "n", "x", "o" }, ",", "<leader>", { remap = true, desc = "Map ',' To Leader" })

-- Quit no-confirm.
set("n", "ZZ", "<cmd>xa<cr>", { desc = "Save All And Quit" })
set("n", "ZQ", "<cmd>qa!<cr>", { desc = "Quit All Without Saving" })

set({ "i", "c" }, "<m-backspace>", "<c-w>", { desc = "Kill Word Backward" })
set({ "i", "c" }, "<c-a>", "<home>", { desc = "Command Line: Home" })
set({ "i", "c" }, "<c-f>", "<right>", { desc = "Command Line: Right" })
set({ "i", "c" }, "<c-b>", "<left>", { desc = "Command Line: Left" })
set({ "i", "c" }, "<c-e>", "<end>", { desc = "Command Line: End" })
set({ "i", "c" }, "<c-d>", "<del>", { desc = "Command Line: Delete" })
set({ "i", "c" }, "<esc>b", "<s-left>", { desc = "Command Line: Word Backward" })
set({ "i", "c" }, "<esc>f", "<s-right>", { desc = "Command Line: Word Forward" })
set({ "i", "c" }, "<c-y>", "<c-r>+", { desc = "Paste From System Clipboard" })
set({ "c" }, "<c-t>", [[<c-r>=expand("%:p:h") . "/" <cr>]], { desc = "Insert Current Directory" })
set("v", "<leader>xs", [[c<C-r>=join(sort(split(@")), ' ')<CR><Esc>]], { desc = "Sort Row Selection" })

-- Disable C-z
set({ "n", "v", "i" }, "<c-z>", "<nop>", { noremap = true, silent = true, desc = "Disable Suspend" })

-- Binds C-c to no highlight.
set("n", "<c-c>", "<esc>:noh<cr>", { noremap = true, silent = true, desc = "Clear Search Highlight" })
set("i", "<c-c>", "<esc>:noh<cr>", { noremap = true, silent = true, desc = "Clear Search Highlight" })

-- Whitespaces.
set("n", "<leader>ds", function()
  local view = vim.fn.winsaveview()
  vim.cmd("keeppatterns %s/\\s\\+$//e")
  vim.fn.winrestview(view)
end, { desc = "Delete Trailing Whitespace" })

local function close_window()
  local ok = pcall(function()
    vim.cmd("close")
  end)

  if not ok then
    pcall(function()
      vim.cmd("bdelete")
    end)
  end
end

-- Generic.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("quit-window", { clear = true }),
  pattern = { "help", "gitsigns-blame", "qf", "oil" },
  callback = function()
    set("n", "q", close_window, { buffer = true, desc = "Close Window" })
    set("n", "<c-c>", close_window, { buffer = true, desc = "Close Window" })
  end,
})

set("n", "gx", function()
  local saved_pos = vim.api.nvim_win_get_cursor(0)

  vim.api.nvim_feedkeys("van", "x", false)

  local mode = vim.fn.mode()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
  local selection = table.concat(lines, "\n")
  selection = (selection:gsub("^%W+", ""):gsub("%W+$", "")) -- trim non alphanumeric

  local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "n", false)
  vim.api.nvim_win_set_cursor(0, saved_pos)

  vim.fn.jobstart({ vim.env.OPENER, selection }, { detach = true })
end, { desc = "Open with system app" })

-- Snacks Picker
local Snacks = require("snacks")

set("n", "<leader>sb", Snacks.picker.lines, { desc = "Search Buffer Lines" })
set("n", "<leader><space>", Snacks.picker.files, { desc = "Find Files" })
set("n", "<leader>fr", Snacks.picker.recent, { desc = "Recent Files (Mru)" })
set("n", "<leader>/", Snacks.picker.grep, { desc = "Live Grep Workspace" })
set("v", "<leader>/", Snacks.picker.grep_word, { desc = "Grep Visual Selection" })
set("v", "<leader>sw", Snacks.picker.grep_word, { desc = "Search Word (Visual)" })
set("n", "<leader>ss", Snacks.picker.lsp_symbols, { desc = "LSP Document Symbols" })
set("n", "<leader>sk", Snacks.picker.keymaps, { desc = "Search Keymaps" })
set("n", "<leader>xx", Snacks.picker.diagnostics_buffer, { desc = "LSP Document Diagnostics" })
set("n", "<leader>gf", Snacks.picker.git_log_file, { desc = "Git Buffer Commits" })
set("n", "<leader>gs", Snacks.picker.git_status, { desc = "Git Status" })
set("n", "<leader>se", Snacks.picker.icons, { desc = "Search Emojis/Icons" })
set("n", "<leader>fp", Snacks.picker.projects, { desc = "Projects" })
set("n", "<leader>gd", Snacks.picker.git_diff, { desc = "Git Diff (Hunks)" })
set("n", '<leader>s"', Snacks.picker.registers, { desc = "Registers" })
set("n", "<leader>,", Snacks.picker.buffers, { desc = "Find Buffers" })
set("n", "<leader>ur", Snacks.picker.resume, { desc = "Picker Resume" })

-- Notifications.
set("n", "<leader>sn", "<cmd>Noice all<cr>", { desc = "Notification Messages" })

-- Toggles
set("n", "<leader>us", function()
  vim.wo.spell = not vim.wo.spell
  vim.notify("Spelling is " .. tostring(vim.wo.spell))
end, { desc = "Toggle Spelling" })

-- Buffers & Windows
set("n", "<leader>bb", "<c-^>", { desc = "Switch last buffer" })
set("n", "<leader>bd", "<cmd>bprevious | bdelete #<cr>", { desc = "Kill current buffer" })
set("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end, { desc = "Delete other buffers" })
set("n", "<leader>wd", "<cmd>close<cr>", { desc = "Delete window" })
set("n", "<leader>wo", "<cmd>only<cr>", { desc = "Delete other windows" })
set("n", "<leader>wq", "<cmd>close<cr>", { desc = "Delete window" })
set("n", "<leader>ws", "<cmd>split<cr>", { desc = "Horizontal split" })
set("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Vertical split" })

local show_diagnostic = function()
  local timer = vim.loop.new_timer()

  if timer then
    timer:start(
      0,
      0,
      vim.schedule_wrap(function()
        vim.diagnostic.open_float(nil, { scope = "cursor" })
      end)
    )
  end
end

set("n", "gd", function()
  local ok, dumb_jump = pcall(require, "rgump.core")
  if ok then
    dumb_jump.jump()
  else
    vim.notify("RGump not available", vim.log.levels.WARN)
  end
end, { desc = "Goto Definition (RGump Fallback)" })

-- Lsp.

local function lsp_action_toggle(front, back)
  return function()
    local found = false

    vim.lsp.buf.code_action({
      apply = true,
      filter = function(action)
        if found then
          return false
        end

        if action.title:match(front) or action.title:match(back) then
          found = true
          return true
        end

        return false
      end,
    })
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local buf = ev.buf
    local s = function(keys, fn, desc)
      set("n", keys, fn, { buffer = buf, desc = desc })
    end

    s("gd", function()
      -- Filter duplicate entries.
      local function on_list(options)
        vim.list.unique(options.items, function(item)
          return string.format("%s:%d:%d", item.filename or item.bufnr, item.lnum, item.col)
        end)

        if #options.items > 1 then
          vim.fn.setqflist({}, " ", options)
          vim.api.nvim_command("copen")
        elseif #options.items == 1 then
          vim.fn.setqflist({}, " ", options)
          vim.api.nvim_command("cfirst")
        end
      end

      -- The global dumb-jump handler override in init.lua will catch empty LSP results
      -- when vim.lsp.buf.definition is called.
      vim.lsp.buf.definition({ on_list = on_list })
    end, "Goto Definition")

    s("gr", vim.lsp.buf.references, "References")
    s("gI", vim.lsp.buf.implementation, "Goto Implementation")
    s("K", vim.lsp.buf.hover, "Hover Docs")
    s("<leader>cr", vim.lsp.buf.rename, "Rename Symbol")

    s("]d", function()
      if not vim.diagnostic.is_enabled({ bufnr = 0 }) then
        return
      end

      vim.diagnostic.jump({ count = 1 })
      show_diagnostic()
    end, "Next Diagnostic")

    s("[d", function()
      if not vim.diagnostic.is_enabled({ bufnr = 0 }) then
        return
      end

      vim.diagnostic.jump({ count = -1 })
      show_diagnostic()
    end, "Prev Diagnostic")

    s("<leader>ca", vim.lsp.buf.code_action, "Code Action List")

    s("<leader>cp", lsp_action_toggle("Introduce pipe", "Remove pipe"), "Apply [P] Action")
    s("<leader>cf", lsp_action_toggle("Rewrite function", "Rewrite keyword function"), "Apply [F] Action")
  end,
})

-- Yanky.
set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Yanky Put After" })
set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Yanky Put Before" })
set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Yanky GPut After" })
set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Yanky GPut Before" })
set("n", "<c-p>", "<Plug>(YankyNextEntry)", { desc = "Yanky Cycle Forward" })
set("n", "<c-n>", "<Plug>(YankyPreviousEntry)", { desc = "Yanky Cycle Backward" })

-- Gitsigns.
set("n", "[x", require("gitsigns").prev_hunk, { desc = "Previous Hunk" })
set("n", "]x", require("gitsigns").next_hunk, { desc = "Next Hunk" })
set("n", "<leader>gu", require("gitsigns").reset_hunk, { desc = "Reset Hunk" })
set("n", "<leader>gp", require("gitsigns").preview_hunk, { desc = "Preview Hunk" })
set("n", "<leader>gb", require("gitsigns").blame, { desc = "Git Blame Line" })

set("n", "<leader>gD", function()
  require("gitsigns").diffthis()
  local buf = vim.api.nvim_get_current_buf()
  set("n", "q", function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local win_buf = vim.api.nvim_win_get_buf(win)
      local buf_name = vim.api.nvim_buf_get_name(win_buf)

      if buf_name:match("^gitsigns://") then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end

    vim.cmd("diffoff!")
    pcall(vim.keymap.del, "n", "q", { buffer = buf })
  end, { buffer = buf, desc = "Close Git Diff" })
end, { desc = "Git Diff Panel" })

-- Smart-splits.
set("n", "<c-h>", require("smart-splits").move_cursor_left, { desc = "Move to Left Split" })
set("n", "<c-j>", require("smart-splits").move_cursor_down, { desc = "Move to Below Split" })
set("n", "<c-k>", require("smart-splits").move_cursor_up, { desc = "Move to Above Split" })
set("n", "<c-l>", require("smart-splits").move_cursor_right, { desc = "Move to Right Split" })
set("n", "<a-s-h>", require("smart-splits").resize_left, { desc = "Resize Split Left" })
set("n", "<a-s-j>", require("smart-splits").resize_down, { desc = "Resize Split Down" })
set("n", "<a-s-k>", require("smart-splits").resize_up, { desc = "Resize Split Up" })
set("n", "<a-s-l>", require("smart-splits").resize_right, { desc = "Resize Split Right" })

-- Grug-Far.
set("n", "<leader>sr", require("grug-far").open, { desc = "Grug-Far Search & Replace" })
set("v", "<leader>sr", require("grug-far").with_visual_selection, { desc = "Grug-Far Search Selection" })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("grug-far-keybindings", { clear = true }),
  pattern = "grug-far",
  callback = function()
    set("n", "q", function()
      require("grug-far").get_instance(0):close()
    end, { buffer = true, desc = "Close Grug-Far" })
  end,
})

-- Quickfix.
set("n", "<leader>xq", function()
  if #vim.tbl_filter(function(w)
    return w.quickfix == 1
  end, vim.fn.getwininfo()) > 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, { desc = "Toggle quickfix" })

-- Toggle term.
set({ "n", "t" }, "<c-_>", require("toggleterm").toggle, { desc = "Toggle Terminal" })
set({ "n", "t" }, "<c-/>", require("toggleterm").toggle, { desc = "Toggle Terminal" })

set({ "n", "t" }, "<a-/>", function()
  local buffer_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  require("toggleterm").toggle(nil, nil, buffer_dir)
end, { desc = "Toggle Terminal in buffer directory" })

-- Treesitter & Inspection.
set("n", "<leader>ut", "<cmd>InspectTree<cr>", { desc = "Inspect Treesitter Tree" })
set("n", "<leader>ui", "<cmd>Inspect<cr>", { desc = "Inspect Symbol Highlight Groups" })

-- Treesitter incremental selection.
set("n", "<C-Space>", function()
  vim.api.nvim_feedkeys("van", "x", false)
end, { desc = "Increment Selection" })
set("x", "<C-Space>", function()
  vim.api.nvim_feedkeys("an", "x", false)
end, { desc = "Increment Selection" })
set("x", "<bs>", function()
  vim.api.nvim_feedkeys("in", "x", false)
end, { desc = "Decrement Selection" })

-- Elixir.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("elixir-tools", { clear = true }),
  pattern = "elixir",
  callback = function()
    set(
      "n",
      "<leader>ct",
      require("elixir_utils").switch_source_test,
      { buffer = true, desc = "Switch source or test" }
    )

    -- Conjure.
    set("n", "<leader>ee", ":ConjureEvalRootForm<CR>", { buffer = true, silent = true, desc = "Eval root" })
    set("v", "<leader>ee", ":ConjureEvalVisual<CR>", { buffer = true, silent = true, desc = "Eval visual" })
    set("n", "<leader>eb", ":ConjureEvalFile<CR>", { buffer = true, silent = true, desc = "Eval buffer" })
    set("n", "<leader>ei", ":ConjureElixirInterrupt<CR>", { buffer = true, silent = true, desc = "Eval interrupt" })
    set("n", "<leader>eq", ":ConjureElixirStop<CR>", { buffer = true, silent = true, desc = "Quit repl" })

    set("n", "<leader>et", function()
      local log_visible = false

      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)

        if buf_name:match("conjure%-log") then
          log_visible = true
          break
        end
      end

      if log_visible then
        vim.cmd("ConjureLogCloseVisible")
      else
        local origin_split_right = vim.opt_local.splitright
        vim.opt_local.splitright = true
        vim.cmd("ConjureLogVSplit")
        vim.opt_local.splitright = origin_split_right
      end
    end, { buffer = true, silent = true, desc = "Toggle repl" })

    set("n", "<leader>er", function()
      local cmd_key = "conjure#client#elixir#stdio#command"
      local current_cmd = vim.b[cmd_key] or vim.g[cmd_key] or "iex --no-color -S mix"

      vim.ui.input({
        prompt = "Repl cmd: ",
        default = current_cmd,
      }, function(input)
        if not input or input == "" then
          return
        end

        local ok = pcall(function()
          vim.cmd("ConjureElixirStop")
          vim.cmd("ConjureLogResetHard")
        end)

        vim.b[cmd_key] = input
        vim.g[cmd_key] = input

        if not ok then
          -- Since conjure dynamically attachs commands, specific filetypes
          -- user commands might be not available if `autorepl` is off, eg:
          -- vim.g["conjure#filetype#elixir"] = false.
          vim.cmd("ConjureAttach")
        else
          vim.cmd("ConjureElixirStart")
        end
      end)
    end, { buffer = true, silent = true, desc = "Repl cmd" })
  end,
})

-- Zk (Zettelkasten).
set("n", "<leader>of", "<cmd>ZkNotes<cr>", { desc = "Zk search notes" })
set("n", "<leader>ot", "<cmd>ZkTags<cr>", { desc = "Zk search by tags" })
set("n", "<leader>ou", "<cmd>ZkIndex<cr>", { desc = "Zk refresh index" })
set("n", "<leader>oc", "<cmd>ZkNew<cr>", { desc = "Zk new note" })
set("n", "<leader>oo", function()
  require("zk").fleeting.open_new()
end, { desc = "Zk new fleeting note" })
set("n", "<leader>oe", function()
  require("zk").fleeting.open_file()
end, { desc = "Zk open fleeting notes" })

set("n", "<leader>os", function()
  local dir = require("config.zk.notebook").dir()
  if not dir then
    vim.notify("ZK_NOTEBOOK_DIR is not set or does not exist", vim.log.levels.WARN)
    return
  end
  Snacks.picker.grep({ cwd = dir })
end, { desc = "Zk grep" })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("zk", { clear = true }),
  pattern = "markdown",
  callback = function()
    set("n", "<leader>ob", "<cmd>ZkBacklinks<cr>", { buffer = true, desc = "Zk backlinks" })
    set("n", "<leader>or", "<cmd>ZkLinks<cr>", { buffer = true, desc = "Zk links" })
    set({ "n", "i" }, "<c-x>", "<cmd>ZkInsertLink<cr>", { buffer = true, desc = "Zk insert link" })
    set("v", "<c-x>", ":ZkInsertLinkAtSelection<cr>", { buffer = true, desc = "Zk insert link selection" })

    set("n", "gX", function()
      vim.fn.jobstart({ "typora", vim.fn.expand("%") }, {
        detach = true,
      })
    end, {
      buffer = true,
      silent = true,
      desc = "Preview in Typora",
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown-mermaid-preview", { clear = true }),
  pattern = { "markdown", "mermaid" },
  callback = function()
    set("n", "<leader>ow", "<cmd>MarkdownPreview<cr>", { buffer = true, desc = "Show markdown preview" })
    set("n", "<leader>or", "<cmd>MarkdownPreviewRefresh<cr>", { buffer = true, desc = "Refresh markdown preview" })
    set("n", "<leader>oq", "<cmd>MarkdownPreviewStop<cr>", { buffer = true, desc = "Stop markdown preview" })
  end,
})

-- Zen-mode & Dashboard.
set("n", "<leader>uz", "<cmd>ZenModeToggle<cr>", { desc = "Toggle Zen Mode" })
set("n", "<leader>uu", "<cmd>Dashboard<cr>", { desc = "Open Dashboard" })

-- Gitlinker.
set({ "n", "v" }, "<leader>gy", require("gitlinker").link, { desc = "Copy git srouce url", silent = true })

-- Oil.
set("n", "-", require("oil").open, { desc = "Oil File Explorer" })

-- Conform formatter.
set("n", "<leader>uf", function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify("Format on save is " .. tostring(not vim.g.disable_autoformat))
end, { desc = "Toggle format on save" })

-- Flash.
set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash" })

set({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash Treesitter" })

-- Tmux.
-- `<c-z>l` in conjuction with TMUX conf.
set("n", "<c-z>l", function()
  if not vim.env.TMUX then
    vim.notify("Tmux is not running")
    return
  end

  local full_path = vim.api.nvim_buf_get_name(0)
  local exec_lf = "$(which lf)"

  if vim.bo.buftype == "" and full_path ~= "" then
    exec_lf = exec_lf .. " " .. full_path
  end

  local cmd = string.format('tmux new-window -c "#{pane_current_path}" "%s"', exec_lf)
  vim.fn.system(cmd)
end, { desc = "Open in LF" })
