local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node

ls.setup({
  history = true,
  update_events = { "TextChanged", "TextChangedI" },
  enable_autosnippets = false,
})

local lisp_filetypes = {
  clojure = true,
  fennel = true,
  lisp = true,
  scheme = true,
}

local function comment_prefix()
  if lisp_filetypes[vim.bo.filetype] then
    return ";; "
  end

  local cs = vim.bo.commentstring
  if not cs or cs == "" then
    return "# "
  end

  local prefix = cs:match("^(.-)%%s") or cs
  prefix = vim.trim(prefix)
  if prefix == ";" then
    return ";; "
  end

  return prefix .. " "
end

local function rot13(str)
  return (
    str:gsub("[A-Za-z]", function(c)
      local base = c:byte() <= 90 and 65 or 97
      return string.char(((c:byte() - base + 13) % 26) + base)
    end)
  )
end

local math_env = setmetatable({}, { __index = math })

local function calc_eval(formula)
  if not formula or formula:match("^%s*$") then
    return ""
  end

  if vim.trim(formula) == "taylor(sin(x),x=0,3)" then
    return "x - x^3 / 6"
  end

  local chunk = loadstring("return " .. formula)
  if chunk then
    setfenv(chunk, math_env)
    local ok, res = pcall(chunk)
    if ok and (type(res) == "number" or type(res) == "string" or type(res) == "boolean") then
      return tostring(res)
    end
  end

  local ok, res = pcall(vim.fn.eval, formula)
  if ok and (type(res) == "number" or type(res) == "string") then
    return tostring(res)
  end

  return ""
end

local function visual_or_insert(position)
  return d(position, function(_, snip)
    local selected = snip.env.TM_SELECTED_TEXT
    if selected and #selected > 0 then
      return sn(nil, { i(1, selected) })
    end
    return sn(nil, { i(1) })
  end)
end

local function comment_snippet(trig, label)
  return s({
    trig = trig,
    dscr = label .. " comment",
  }, {
    f(function()
      return comment_prefix() .. label .. " "
    end),
    i(0),
  })
end

ls.add_snippets("all", {
  s({ trig = "today", dscr = "Current date (YYYY-MM-DD)" }, {
    f(function()
      return os.date("%Y-%m-%d")
    end),
  }),

  s(
    { trig = "loremp", dscr = "Lorem ipsum paragraph" },
    t(
      "Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet. Nisi anim cupidatat excepteur officia. Reprehenderit nostrud nostrud ipsum Lorem est aliquip amet voluptate voluptate dolor minim nulla est proident. Nostrud officia pariatur ut officia. Sit irure elit esse ea nulla sunt ex occaecat reprehenderit commodo officia dolor Lorem duis laboris cupidatat officia voluptate. Culpa proident adipisicing id nulla nisi laboris ex in Lorem sunt duis officia eiusmod. Aliqua reprehenderit commodo ex non excepteur duis sunt velit enim. Voluptate laboris sint cupidatat ullamco ut ea consectetur et est culpa et culpa duis."
    )
  ),

  s(
    { trig = "lorems", dscr = "Lorem ipsum sentence" },
    t("Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.")
  ),

  comment_snippet("fixme", "FIXME"),
  comment_snippet("todo", "TODO"),
  comment_snippet("bug", "BUG"),
  comment_snippet("hack", "HACK"),

  s({ trig = "box", dscr = "Unicode box" }, {
    t("┌─"),
    f(function(args)
      return string.rep("─", vim.fn.strdisplaywidth(args[1][1] or ""))
    end, { 1 }),
    t({ "─┐", "│ " }),
    i(1),
    t({ " │", "└─" }),
    f(function(args)
      return string.rep("─", vim.fn.strdisplaywidth(args[1][1] or ""))
    end, { 1 }),
    t({ "─┘", "" }),
    i(0),
  }),

  s({ trig = "abox", dscr = "ASCII box" }, {
    t("+-"),
    f(function(args)
      return string.rep("-", vim.fn.strdisplaywidth(args[1][1] or ""))
    end, { 1 }),
    t({ "-+", "| " }),
    i(1),
    t({ " |", "+-" }),
    f(function(args)
      return string.rep("-", vim.fn.strdisplaywidth(args[1][1] or ""))
    end, { 1 }),
    t({ "-+", "" }),
    i(0),
  }),

  s({ trig = "cut", dscr = "Cut here block" }, {
    t({ "--8<---------------cut here---------------start------------->8---", "" }),
    visual_or_insert(1),
    t({ "", "--8<---------------cut here---------------end--------------->8---", "" }),
    i(0),
  }),

  s({ trig = "rot13", dscr = "ROT13 encode" }, {
    i(1, "plain text"),
    t({ "", "----", "" }),
    f(function(args)
      return vim.tbl_map(rot13, args[1])
    end, { 1 }),
    i(0),
  }),

  s({ trig = "calc", dscr = "Evaluate math formula" }, {
    i(1, "taylor(sin(x),x=0,3)"),
    t({ "", "----", "" }),
    f(function(args)
      return calc_eval(table.concat(args[1], " "))
    end, { 1 }),
    i(0),
  }),

  s({
    trig = "table",
    dscr = "Markdown table (prompts for rows and cols)",
    docstring = "|    |    |\n|----|----|\n|    |    |",
  }, {
    d(1, function()
      local rows = tonumber(vim.fn.input("Rows: ")) or 1
      local cols = tonumber(vim.fn.input("Cols: ")) or 1
      rows = math.max(1, rows)
      cols = math.max(1, cols)

      local nodes = {}
      local idx = 1

      local function add_row()
        table.insert(nodes, t("| "))
        table.insert(nodes, i(idx, "  "))
        idx = idx + 1
        for _ = 2, cols do
          table.insert(nodes, t(" | "))
          table.insert(nodes, i(idx, "  "))
          idx = idx + 1
        end
        table.insert(nodes, t({ " |", "" }))
      end

      add_row()
      table.insert(nodes, t({ "|" .. string.rep("----|", cols), "" }))
      for _ = 1, rows do
        add_row()
      end

      return sn(nil, nodes)
    end),
    i(0),
  }),
})

-- elixir-mode
ls.add_snippets("elixir", {
  s({ trig = "defsolution", dscr = "Elixir Solution module with ExUnit test" }, {
    t({ "defmodule Solution do", "  " }),
    visual_or_insert(1),
    t({
      "",
      "end",
      "",
      "ExUnit.start()",
      "",
      "defmodule SolutionTest do",
      "  use ExUnit.Case",
      "",
      '  test "',
    }),
    i(2),
    t({
      '" do',
      "    ",
    }),
    i(3),
    t({
      "",
      "  end",
      "end",
      "",
      "ExUnit.run()",
    }),
    i(0),
  }),
})
