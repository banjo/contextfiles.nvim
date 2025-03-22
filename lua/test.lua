local context = require("context-files")

local current_file_path = vim.api.nvim_buf_get_name(0)
local files = context.get_context_files(current_file_path, { gist_ids = { "<gist_id>" } })
