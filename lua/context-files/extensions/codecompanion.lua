local core = require("context-files.core")

local M = {}

--- Get the context for the current file in a CodeCompanion prompt friendly format
---@param file string Path to the current file
---@param opts FormatOpts? Options for formatting the output
function M.get(file, opts)
  opts = vim.tbl_deep_extend("force", core.FORMAT_DEFAULTS, opts or {})

  local files = core.get_context_files(file, opts)
  local formatted = core.format(files, opts.format_opts)

  -- Remove "#" from the formatted string as the buffer uses that for separating
  return formatted:gsub("#", "-")
end

return M
