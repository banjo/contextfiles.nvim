# contextfiles.nvim

A Neovim utility plugin to find related context files for a file. Scan for [Project files](https://docs.cursor.com/context/rules-for-ai) in your repository and add them to your LLM chats for optimal results.

## Features

- 📁 Scan project directories for contextual rule files (e.g. `.cursor/rules`)
- 🔍 Match files based on glob patterns in frontmatter (e.g. `globs: "*.md"`)
- ☁️ Fetch contexts from GitHub Gists
- 🔨 Simple API - extend and do whatever you want with the files

## Installation

> ⚠️ **Warning**
> Neovim >= 0.11 is highly recommended to avoid any pattern matching issues (see [this issue](https://github.com/neovim/neovim/issues/28931) and [this PR](https://github.com/neovim/neovim/pull/29236))

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "banjo/contextfiles.nvim",
}
```

## Supported glob pattern styles

You can specify glob patterns in your context files using several styles. **Quotes are always stripped from patterns before matching.**

- **Comma-separated patterns:**
  ```md
  globs: *.ts,*.js
  ```
- **Array syntax (recommended for complex patterns):**
  ```md
  globs: ["*.ts", "*.js"]
  globs: ['*.ts','*.js']
  globs: [ "*.ts" , "*.js" ]
  globs: ["*.ts", "*.js",]
  globs: ["*.ts", '*.js']
  ```
- **Single pattern:**
  ```md
  globs: "*.lua"
  globs: '*.lua'
  globs: *.lua
  ```
- **Brace expansion:**
  ```md
  globs: **/file.{ts,js}
  globs: ["**/file.{ts,js}"]
  ```
- **Patterns with character classes:**
  ```md
  globs: foo[ab,cd],bar
  ```
- **Patterns with commas inside quotes, braces, or brackets:**
  ```md
  globs: "foo,bar.js",baz.js
  globs: foo,{bar,baz},qux
  globs: foo[ab,cd],bar
  globs: foo,{bar,[baz,qux]},other
  ```
  > Quotes are stripped, so `"foo,bar.js"` becomes `foo,bar.js`.
- **No globs:**
  If no `globs:` line is present, the rule applies to all files.

### Example frontmatter

```md
---
globs: ["**/*.md", "*.txt"]
---
# Markdown guidelines
- Format this way
- Do that
```

## Running Tests

To run the plugin's tests, use:

```bash
make test
```

This will execute all tests in `tests/core_test.lua` using Neovim in headless mode.

## Usage

- Add the appropriate context files in a folder in your repository (default is `.cursor/rules`)

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

contextfiles provides a simple way to concatenate all files to a simple string.

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
{
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "banjo/contextfiles.nvim",
  },
  extensions = {
    contextfiles = {
      opts = {
        -- your contextfiles configuration here
        -- or leave it empty to use the default configuration
      },
    },
  },
  -- ...
}
```

<details>
<summary>Default configuration</summary>

```lua
{
  slash_command = {
    enabled = true,
    name = "context",
    ctx_opts = {
      context_dir = ".cursor/rules",
      root_markers = { ".git" },
      gist_ids = {},
      enable_local = true,
    },
    format_opts = {
      ---@param context_file ContextFiles.ContextFile the context file to prepend the prefix
      prefix = function(context_file)
        return string.format("Please follow the rules located at `%s`:", vim.fn.fnamemodify(context_file.file, ":."))
      end,
      suffix = "",
      separator = "",
    }
  },
}
```

</details>

Then, you can use the slash command `/context` to include the context files in your chats.

You can also use directly in your own prompts:

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
        local ctx = require("codecompanion").extensions.contextfiles

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

The default folder for context files would be `.cursor/rules`, so by adding the following example file:

```md
---
globs: ["**/*.md"]
---
# Markdown guidelines
- Format this way
- Do that
```

And opening the custom prompt in any markdown file:

```lua
require("codecompanion").prompt("context")
```

The buffer will be populated with the content of the context file.

- All `#` will be replaced with `-` as they are used as separators in the chat buffer.
- It works the same as the core API - you can get files from a local folder or from Github gists.

## Default behaviors

- If no context files are found, an empty table is returned.
- If a context file is found but no globs are specified, it is considered a match.
