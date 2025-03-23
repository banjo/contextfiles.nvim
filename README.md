# contextfiles.nvim

A Neovim utility plugin to find related context files for a file. Scan for [Project files](https://docs.cursor.com/context/rules-for-ai) in your repository and add them to your LLM chats for optimal results.

## Features

- 📁 Scan project directories for contextual rule files (e.g. `.cursor/rules`)
- 🔍 Match files based on glob patterns in frontmatter (e.g. `match: "*.md"`)
- ☁️ Fetch contexts from GitHub Gists
- 🔨 Simple API - extend and do whatever you want with the files

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

## Project files

It is possible to read more about what Cursor calls project files [here](https://docs.cursor.com/context/rules-for-ai). In short terms, it is basically files that allow you to add context to specific files. This plugin will allow you to scan for the appropriate files based on the what file file you provide, and the specified glob pattern in the context file. A lot of examples can be found [here](https://cursor.directory/rules).

```md
---
globs: ["**/*.md"]
---

# Markdown guidelines

- Format this way
- Do that
```

- This file would be included if you would work in any `.md` markdown file in the repository
- Only the content (below the frontmatter) would be included

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
    patterns = { "**/*.md" },
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

First you need to add it to the dependencies for `CodeCompanion`:

```lua

{ "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "banjo/contextfiles.nvim",
  },
  -- ...
}
```

And then create your prompt:

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
