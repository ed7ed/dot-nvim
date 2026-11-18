-- Ensure the plugin's own plugin/bookmarks.lua runs first so it doesn't
-- reset `vim.g.bookmarks_config = nil` after our setup() call.
for _, file in ipairs(vim.api.nvim_get_runtime_file("plugin/bookmarks.lua", true)) do
  if not vim.startswith(file, vim.fn.stdpath("config")) then
    dofile(file)
  end
end

local sign = require("bookmarks.sign")
sign.place_sign = function(line, buf_number)
  vim.fn.sign_place(line, "BookmarksNvim", "BookmarksNvimSign", buf_number, { lnum = line })
end

require("bookmarks").setup({
  signs = {
    mark = {
      icon = "󰎚",
      color = "",
      line_bg = "",
    },
  },
  picker = {
    picker_backend = "snacks",
  },
})

-- Override Snacks bookmark picker so it displays and searches by bookmark name
-- instead of file path.
local bookmark_picker = require("bookmarks.picker.snacks.bookmark-picker")
bookmark_picker.pick_bookmark = function(callback, opts)
  opts = opts or {}
  local Repo = require("bookmarks.domain.repo")
  local Service = require("bookmarks.domain.service")
  local Node = require("bookmarks.domain.node")

  local active_list = Repo.ensure_and_get_active_list()
  local bookmarks = opts.bookmarks or Node.get_all_bookmarks(active_list)

  local max_name = 15
  for _, bm in ipairs(bookmarks) do
    max_name = math.max(max_name, #bm.name)
  end
  max_name = math.min(max_name, 40)

  local items = {}
  for _, bookmark in ipairs(bookmarks) do
    table.insert(items, {
      text = bookmark.name,
      file = bookmark.location.path,
      pos = { bookmark.location.line, bookmark.location.col },
      bookmark = bookmark,
    })
  end

  Snacks.picker({
    title = opts.prompt or "Bookmarks",
    items = items,
    format = function(item)
      local name = item.text
      local pad = string.rep(" ", math.max(0, max_name - vim.fn.strdisplaywidth(name)))
      local filename = vim.fn.fnamemodify(item.file, ":t") .. ":" .. item.pos[1]
      return {
        { name },
        { pad .. " │ " .. filename, "SnacksPickerComment", virtual = true },
      }
    end,
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        callback(item.bookmark)
      end
    end,
    actions = {
      delete_bookmark = function(picker, item)
        if not item or not item.bookmark then
          return
        end
        Service.delete_node(item.bookmark.id)
        require("bookmarks.sign").safe_refresh_signs()
        picker:close()
        vim.schedule(function()
          bookmark_picker.pick_bookmark(callback, opts)
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "delete_bookmark", mode = { "i", "n" }, desc = "Delete bookmark" },
        },
      },
    },
  })
end

-- Always use the single global root bookmark list (id = 0).
pcall(function()
  require("bookmarks.domain.service").set_active_list(0)
end)

vim.api.nvim_set_hl(0, "BookmarksNvimSign", { link = "DiagnosticSignWarn" })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("bookmarks-highlights", { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, "BookmarksNvimSign", { link = "DiagnosticSignWarn" })
  end,
})

-- Bookmarks.
vim.keymap.set({ "n", "v" }, "<leader>mm", "<cmd>BookmarksMark<cr>", { desc = "Toggle bookmark" })
vim.keymap.set({ "n", "v" }, "<leader>ma", "<cmd>BookmarksGoto<cr>", { desc = "List all bookmarks" })
vim.keymap.set({ "n", "v" }, "<leader>md", function()
  local Service = require("bookmarks.domain.service")
  local Sign = require("bookmarks.sign")
  local Tree = require("bookmarks.tree.operate")
  local bookmark = Service.find_bookmark_by_location()
  if bookmark then
    Service.remove_bookmark(bookmark.id)
    Sign.safe_refresh_signs()
    pcall(Tree.refresh)
  else
    vim.notify("No bookmark on current line", vim.log.levels.WARN)
  end
end, { desc = "Delete bookmark" })
