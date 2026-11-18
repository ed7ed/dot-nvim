vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  callback = function()
    vim.api.nvim_set_hl(0, "FloatBorder", { link = "Function" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = "NONE" })

    for _, group in ipairs({ "@markup.link", "@markup.link.url", "@markup.link.label", "@markup.link.markdown_inline" }) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false, create = false })
      if not vim.tbl_isempty(hl) then
        vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", hl, { underline = false }))
      end
    end
  end,
})

require("catppuccin").setup({
  custom_highlights = function(colors)
    return {
      NotifyINFOTitle = { fg = colors.green },
      NotifyINFOIcon = { fg = colors.green },
      NotifyINFOBorder = { fg = colors.green },
      ["@markup.link"] = { fg = colors.surface2 },
      ["@markup.link.url"] = { fg = colors.surface2 },
      ["@conceal"] = { fg = colors.surface2 },
      ["@markup.raw.markdown_inline"] = { fg = colors.sapphire },
    }
  end,
})

require("tokyonight").setup({
  on_highlights = function(hl, c)
    hl.NotifyINFOTitle = { fg = c.green }
    hl.NotifyINFOIcon = { fg = c.green }
    hl.NotifyINFOBorder = { fg = c.green }

    hl["@markup.link"] = { fg = c.comment }
    hl["@markup.link.url"] = { fg = c.comment }
    hl["@conceal"] = { fg = c.comment }
    hl["@markup.heading.1.markdown"] = { fg = c.blue, bold = true }
    hl["@markup.heading.2.markdown"] = { fg = c.yellow, bold = true }
    hl["@markup.heading.3.markdown"] = { fg = c.green, bold = true }
    hl["@markup.heading.4.markdown"] = { fg = c.teal, bold = true }
    hl["@markup.heading.5.markdown"] = { fg = c.magenta, bold = true }
    hl["@markup.heading.6.markdown"] = { fg = c.purple, bold = true }
    hl["@markup.raw.markdown_inline"] = { fg = c.blue }
  end,
})

vim.cmd("colorscheme catppuccin-latte")

local theme_reload_watcher = function()
  local watcher = assert(vim.uv.new_fs_event(), "Failed to create watcher")
  local filepath = vim.fs.joinpath(vim.fn.stdpath("state"), "theme.lua")
  local transpath = vim.fn.stdpath("config") .. "/plugin/transparency.lua"
  local watch_dir = vim.fn.fnamemodify(filepath, ":h")

  local on_change = function(_, _, _)
    vim.schedule(function()
      dofile(filepath)
      dofile(transpath)
    end)
  end

  vim.uv.fs_event_start(watcher, watch_dir, {}, on_change)
end

theme_reload_watcher()
