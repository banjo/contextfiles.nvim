---@module "codecompanion"

local core = require("contextfiles.core")

---Get the context for the current file in a CodeCompanion prompt friendly format
---@param file string path to the current file
---@param ctx_opts ContextFiles.Opts? configuration options
---@param format_opts ContextFiles.FormatOpts? options for formatting the output
local function get(file, ctx_opts, format_opts)
  local files = core.get_context_files(file, ctx_opts)
  local formatted = core.format_multiple_files(files, format_opts)

  -- Remove "#" from the formatted string as the buffer uses that for separating
  return formatted:gsub("#", "-")
end

---Register the slash command to CodeCompanion
---@param opts ContextFiles.CodeCompanion.Opts configuration options
local function register_slash_command(opts)
  if not opts.slash_command.enabled then
    return
  end

  local slash_commands = require("codecompanion.config").config.strategies.chat.slash_commands

  if slash_commands[opts.slash_command.name] ~= nil then
    vim.notify(
      string.format(
        "There's already an existing slash command named `%s`. Please either remove it or rename it.",
        opts.slash_command.name
      ),
      vim.log.levels.ERROR,
      { title = "ContextFiles" }
    )
    return
  end

  slash_commands[opts.slash_command.name] = {
    description = "Add context files to the codebase.",
    ---@param chat CodeCompanion.Chat
    callback = function(chat)
      local context_files = core.get_context_files(chat.context.filename, opts.slash_command.ctx_opts)

      for _, context_file in ipairs(context_files) do
        local relative_path = vim.fn.fnamemodify(context_file.file, ":.")
        local id = "<file>" .. relative_path .. "</file>"

        chat:add_message(
          { content = core.format(context_file, opts.slash_command.format_opts), role = "user" },
          { visible = false, id = id }
        )
        chat.references:add({
          source = "ContextFiles",
          name = context_file,
          id = id or "",
        })
      end
    end,
  }
end

---@class ContextFiles.CodeCompanion.SlashCommandOpts
---@field enabled boolean add slash command to CodeCompanion
---@field name string command name to register in CodeCompanion
---@field ctx_opts ContextFiles.Opts? the ContextFiles configuration options
---@field format_opts ContextFiles.FormatOpts? the configuration options for formatting

---@class ContextFiles.CodeCompanion.Opts
---@field slash_command ContextFiles.CodeCompanion.SlashCommandOpts

---@class CodeCompanion.Extension
---@field setup fun(opts: table) function called when extension is loaded
---@field exports? table functions exposed via codecompanion.extensions.your_extension
local M = {}

---Setup the extension
---@param opts ContextFiles.CodeCompanion.Opts Configuration options
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", {
    slash_command = {
      enabled = true,
      name = "context",
      format_opts = {
        ---@param context_file ContextFiles.ContextFile the file to prepend the prefix
        prefix = function(context_file)
          return string.format("Please follow the rules located at `%s`:", vim.fn.fnamemodify(context_file.file, ":."))
        end,
        suffix = "",
        separator = "",
      },
      ctx_opts = core.OPTS_DEFAULTS,
    },
  }, opts or {})

  register_slash_command(opts)
end

M.exports = { get = get }

return M
