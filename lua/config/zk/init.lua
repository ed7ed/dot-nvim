local fleeting = require("config.zk.fleeting")
local frontmatter = require("config.zk.frontmatter")
local history = require("config.zk.history")
local notebook = require("config.zk.notebook")

local M = {
  notebook = notebook,
  history = history,
  frontmatter = frontmatter,
  fleeting = fleeting,
}

function M.setup()
  local zk = require("zk")
  zk.setup({ picker = "select" })

  zk.fleeting = fleeting

  history.setup(zk)
  frontmatter.setup()
  fleeting.setup()
end

return M
