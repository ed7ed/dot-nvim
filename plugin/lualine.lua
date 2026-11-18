local function selected_indicator()
  local mode = vim.fn.mode()
  if not mode:find("[vV\22]") then
    return ""
  end -- only in visual modes
  local start = vim.fn.getpos("v")
  local finish = vim.fn.getpos(".")
  local lines = math.abs(finish[2] - start[2]) + 1
  local chars = vim.fn.wordcount().visual_chars
  if lines == 1 then
    return chars .. "c"
  else
    return lines .. "L " .. chars .. "c"
  end
end

local function int_to_hex(color)
  return string.format("#%06x", color)
end

local function hl_fg(name)
  local fg = vim.api.nvim_get_hl(0, { name = name }).fg
  return fg and int_to_hex(fg) or nil
end

local function get_cached_project_root()
  if vim.b.project_root_cache ~= nil then
    return vim.b.project_root_cache == false and nil or vim.b.project_root_cache
  end

  local home = vim.uv.os_homedir()
  local patterns = require("project_root").patterns() or { ".git" }
  local root = vim.fs.root(0, { patterns })
  if root == home then
    root = nil
  end
  if not root then
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if client.root_dir and client.root_dir ~= home then
        root = client.root_dir
        break
      end
    end
  end

  if root then
    vim.b.project_root_cache = root
    return root
  end

  vim.b.project_root_cache = false
  return nil
end

local function filename()
  local root = get_cached_project_root()
  local path = vim.api.nvim_buf_get_name(0)

  if root and #root > 0 and vim.startswith(path, root) then
    return path:sub(#root + 2)
  end

  return vim.fn.fnamemodify(path, ":t")
end

local function project_dir()
  local fullpath = get_cached_project_root()

  if fullpath then
    return "[" .. vim.fs.basename(fullpath) .. "]"
  end

  return "[No Project]"
end

local function project_dir_color()
  return { gui = "bold", fg = hl_fg("DiagnosticHint") }
end

local function location()
  if vim.bo.buftype ~= "" then
    return ""
  end

  return "%3l:%-2c"
end

local function macro_color()
  return { fg = hl_fg("ErrorMsg") }
end

local function lsp()
  local clients = vim.tbl_filter(function(cli)
    return cli.name ~= "zk"
  end, vim.lsp.get_clients({ bufnr = 0 }))

  if #clients == 0 then
    return ""
  end

  local client_names = {}
  local workspace = ""

  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)

    if workspace == "" then
      if client.workspace_folders and #client.workspace_folders > 0 then
        workspace = vim.fn.fnamemodify(client.workspace_folders[1].name, ":t")
      elseif client.config and client.config.root_dir then
        workspace = vim.fn.fnamemodify(client.config.root_dir, ":t")
      elseif client.root_dir then
        workspace = vim.fn.fnamemodify(client.root_dir, ":t")
      end
    end
  end

  if workspace == "" then
    workspace = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  end

  return " [" .. workspace .. ":" .. table.concat(client_names, ",") .. "]"
end

local function lsp_color()
  if not vim.diagnostic.is_enabled({ bufnr = 0 }) then
    return
  end

  local severity = vim.diagnostic.severity

  local levels = {
    { severity.ERROR, "DiagnosticError" },
    { severity.WARN, "DiagnosticWarn" },
    { severity.INFO, "DiagnosticInfo" },
    { severity.HINT, "DiagnosticHint" },
  }

  for _, level in ipairs(levels) do
    if #vim.diagnostic.get(0, { severity = level[1] }) > 0 then
      return { fg = hl_fg(level[2]), gui = "bold" }
    end
  end

  return { fg = hl_fg("DiagnosticHint"), gui = "bold" }
end

local function macro()
  if vim.fn.reg_recording() ~= "" then
    return ""
  else
    return ""
  end
end

local function spell()
  if not vim.wo.spell then
    return ""
  end
  return ""
end

local function branch()
  if vim.b.gitsigns_head and #vim.b.gitsigns_head > 0 then
    return "󰘬 " .. vim.b.gitsigns_head
  end

  return ""
end

require("lualine").setup({
  options = {
    component_separators = "", -- no separators between components
    section_separators = "", -- no separators between sections (flat style)
    globalstatus = vim.o.laststatus == 3,
    disabled_filetypes = { statusline = { "dashboard" } },
  },

  sections = {
    lualine_a = { "searchcount" },
    lualine_b = {},
    lualine_c = {
      { "filetype", icon_only = true, separator = "", padding = { left = 2 } },
      { project_dir, color = project_dir_color, padding = { left = 2, right = 0 } },
      { filename, color = { gui = "bold" } },
      { location, padding = { left = 2 } },
      {
        selected_indicator,
        color = { gui = "bold" },
        padding = { left = 2 },
      },
      { macro, padding = { left = 4 }, color = macro_color },
      { spell, padding = { left = 4 } },
    },
    lualine_x = {
      { lsp, color = lsp_color, padding = { left = 2 } },
      { branch, color = { gui = "bold" } },
    },
    lualine_y = {},
    lualine_z = {},
  },
})
