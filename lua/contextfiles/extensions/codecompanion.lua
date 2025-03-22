local core = require("contextfiles.core")

local M = {}

--- Get the context for the current file in a CodeCompanion prompt friendly format
---@param file string Path to the current file
---@param ctx_opts ContextFilesOptions? configuration options
---@param format_opts FormatOpts? Options for formatting the output
function M.get(file, ctx_opts, format_opts)
  local files = core.get_context_files(file, ctx_opts)
  local formatted = core.format(files, format_opts)

  -- Remove "#" from the formatted string as the buffer uses that for separating
  return formatted:gsub("#", "-")
end

return M
