# contextfiles.nvim

A Neovim plugin to scan, match, and format context files (or project files) for use in AI assistants and other tools.

## Features

- Scan project directories for contextual rule files (e.g. `.cursor/rules`)
- Match files based on glob patterns in frontmatter (e.g. `match: "*.md"`)
- Fetch contexts from GitHub Gists
- Format contexts for various AI assistant integrations

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "banjo/contextfiles.nvim",
}
```

## Usage

### Scanning Context Files

You can get all the context files for the current file by using the `get_context_files` function.

```lua
local context = require("contextfiles")

local current_file_path = vim.api.nvim_buf_get_name(0)
local files = context.get_context_files(current_file_path, { context_dir = ".cursor/rules" })
```

### Fetch context files from GitHub Gists

You can fetch context files from GitHub Gists by passing the gist ids. If you want, you can also disable local scanning and just fetch context from gists.

```lua
local files = context.get_context_files(current_file_path, { gist_ids = { "<gist_id>" }, enable_local = false })
```

### Format files to one string

contextfiles provides a simple way to concatonate all files to a simple string.

```lua

local files = context.get_context_files(current_file_path)
local formatted = context.format(files, { separator = "\n" })
```

## Default options

### Context options

```lua
{
  context_dir = ".cursor/rules",
  root_markers = { ".git" },
  gist_ids = {},
  enable_local = true,
}
```

- `context_dir`: The directory where the context files are stored. Default: `.cursor/rules`
- `root_markers`: The root markers to look for when scanning for context files. Files that mark the root folder. Default: `[".git"]`
- `gist_ids`: The gist ids to fetch context files from. Default: `{}`
- `enable_local`: Enable local scanning. Default: `true`

### Format options

```lua

{
  prefix = "Here is context for the current file, separated by `---`: \n\n---",
  suffix = "\n\n---\n\n The following is the user prompt: \n\n---\n\n",
  separator = "\n\n---\n\n",
}
```

- `prefix`: The prefix to add to the formatted string. Default: `Here is context for the current file, separated by '---': \n\n---`
- `suffix`: The suffix to add to the formatted string. Default: `\n\n---\n\n The following is the user prompt: \n\n---\n\n`
- `separator`: The separator to add between each context file. Default: `\n\n---\n\n`

## Output format

The output format is a simple table containing the following fields:

- file: The path to the rule file
- patterns: An array of glob patterns parsed from the file
- content: An array of lines from the file with frontmatter removed

```lua
{
  {
    file = ".cursor/rules/README.md",
    patterns = { "*.md" },
    content = {
      "This is a context file",
      "It contains some rules",
    },
  },
}
```

## Extensions

### CodeCompanion

To create custom prompts in `CodeCompanion`, you can use the extension provided by `contextfiles`. Use the util functions in a custom prompt to get the context files. It will be formatted to work with the CodeCompanion chat buffer.

```lua
["context"] = {
  strategy = "chat",
  description = "Chat with context files",
  opts = {
    -- ...
  },
  prompts = {
    {
      role = "user",
      opts = {
        contains_code = true,
      },
      content = function(context)
        local ctx = require("contextfiles.extensions.codecompanion")

        local ctx_opts = {
          -- ...
        }
        local format_opts = {
          -- ...
        }

        return ctx.get(context.filename, ctx_opts, format_opts)
      end,
    },
  },
}
```

- All `#` will be replaced with `-` as they are used as separators in the chat buffer.

## Default behaviors

- If no context files are found, an empty table is returned.
- If a context file is found but no globs are specified, it is considered a match.
