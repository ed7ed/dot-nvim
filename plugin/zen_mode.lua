local M = {}

M.active = false
M.saved_state = {}
M.bg_win = nil
M.zen_win = nil
M.augroup = vim.api.nvim_create_augroup("CustomZenMode", { clear = true })

M.config = {
  window = {
    width = function()
      return math.max(vim.bo.textwidth, 80)
    end,
    options = {
      number = false,
      relativenumber = false,
      signcolumn = "no",
      foldcolumn = "0",
      statuscolumn = "",
      colorcolumn = "",
      wrap = true,
      fillchars = "eob: ,fold:.,vert: ",
    },
  },
  global = {
    options = {
      laststatus = 0,
    },
  },
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.get_layout()
  local ui_width = vim.o.columns
  local ui_height = vim.o.lines

  local w = M.config.window.width()
  local c = math.max(0, math.floor((ui_width - w) / 2))
  local h = math.max(1, ui_height - vim.o.cmdheight)

  return {
    bg = {
      relative = "editor",
      width = ui_width,
      height = ui_height,
      col = 0,
      row = 0,
    },
    zen = {
      relative = "editor",
      width = w,
      height = h,
      col = c,
      row = 0,
    },
  }
end

function M.close_windows()
  if M.zen_win and vim.api.nvim_win_is_valid(M.zen_win) then
    pcall(vim.api.nvim_win_close, M.zen_win, true)
  end
  if M.bg_win and vim.api.nvim_win_is_valid(M.bg_win) then
    pcall(vim.api.nvim_win_close, M.bg_win, true)
  end
  M.zen_win = nil
  M.bg_win = nil
end

function M.apply_zen_options()
  if not M.zen_win or not vim.api.nvim_win_is_valid(M.zen_win) then
    return
  end
  for k, v in pairs(M.config.window.options) do
    vim.api.nvim_set_option_value(k, v, { win = M.zen_win })
  end
end

function M.resize_windows()
  if not M.active then
    return
  end
  local layout = M.get_layout()

  if M.bg_win and vim.api.nvim_win_is_valid(M.bg_win) then
    vim.api.nvim_win_set_config(M.bg_win, layout.bg)
  end

  if M.zen_win and vim.api.nvim_win_is_valid(M.zen_win) then
    vim.api.nvim_win_set_config(M.zen_win, layout.zen)
  end
end

function M.setup_autocommands()
  vim.api.nvim_clear_autocmds({ group = M.augroup })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = M.augroup,
    callback = function()
      local current = vim.api.nvim_get_current_win()
      local cfg = vim.api.nvim_win_get_config(current)

      if cfg.relative == "" and current ~= M.zen_win then
        vim.defer_fn(function()
          if not M.active then
            return
          end
          local after_win = vim.api.nvim_get_current_win()
          local after_cfg = vim.api.nvim_win_get_config(after_win)

          if after_cfg.relative == "" then
            local new_buf = vim.api.nvim_win_get_buf(after_win)
            if M.zen_win and vim.api.nvim_win_is_valid(M.zen_win) then
              vim.api.nvim_win_set_buf(M.zen_win, new_buf)
              vim.api.nvim_set_current_win(M.zen_win)
              M.apply_zen_options()
            end
          end
        end, 10)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = M.augroup,
    callback = function()
      if M.active and vim.api.nvim_get_current_win() == M.zen_win then
        M.apply_zen_options()
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = M.augroup,
    callback = M.resize_windows,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = M.augroup,
    pattern = tostring(M.zen_win),
    callback = function()
      if M.active then
        vim.schedule(M.toggle)
      end
    end,
  })
end

function M.open()
  M.saved_state = {
    global = {},
    orig_win = vim.api.nvim_get_current_win(),
  }
  for k, _ in pairs(M.config.global.options) do
    M.saved_state.global[k] = vim.opt[k]:get()
  end

  for k, v in pairs(M.config.global.options) do
    vim.opt[k] = v
  end

  local buf = vim.api.nvim_get_current_buf()
  local layout = M.get_layout()

  local bg_buf = vim.api.nvim_create_buf(false, true)
  layout.bg.style = "minimal"
  layout.bg.zindex = 30
  M.bg_win = vim.api.nvim_open_win(bg_buf, false, layout.bg)
  vim.api.nvim_set_option_value("winhl", "Normal:Normal", { win = M.bg_win })

  layout.zen.style = "minimal"
  layout.zen.zindex = 50 -- adjust for smart-splits
  M.zen_win = vim.api.nvim_open_win(buf, true, layout.zen)

  M.apply_zen_options()
  M.active = true
  M.setup_autocommands()
end

function M.close()
  M.active = false
  vim.api.nvim_clear_autocmds({ group = M.augroup })

  local cur_buf = nil
  if M.zen_win and vim.api.nvim_win_is_valid(M.zen_win) then
    cur_buf = vim.api.nvim_win_get_buf(M.zen_win)
  end

  M.close_windows()

  for k, v in pairs(M.saved_state.global or {}) do
    vim.opt[k] = v
  end

  if M.saved_state.orig_win and vim.api.nvim_win_is_valid(M.saved_state.orig_win) then
    if cur_buf then
      vim.api.nvim_win_set_buf(M.saved_state.orig_win, cur_buf)
    end
    vim.api.nvim_set_current_win(M.saved_state.orig_win)
  end
end

function M.toggle()
  if M.active then
    M.close()
  else
    M.open()
  end
end

vim.api.nvim_create_user_command("ZenModeToggle", M.toggle, {})

return M
