local M = {}

M.FORMAT_DEFAULTS = {
  prefix = "Here is context for the current file, separated by `---`: \n\n---",
  suffix = "\n\n---\n\n The following is the user prompt: \n\n---\n\n",
  separator = "\n\n---\n\n",
}

M.OPTS_DEFAULTS = {
  context_dir = ".cursor/rules",
  root_markers = { ".git" },
  gist_ids = {},
  enable_local = true,
}

local function find_root_dir(file_path, root_markers)
  local root_dir = vim.fn.fnamemodify(file_path, ":h") -- Start with buffer directory

  -- Walk up the directory tree until we find a marker
  while root_dir ~= "/" do
    local found = false
    for _, marker in ipairs(root_markers) do
      if vim.fn.isdirectory(root_dir .. "/" .. marker) == 1 or vim.fn.filereadable(root_dir .. "/" .. marker) == 1 then
        found = true
        break
      end
    end

    if found then
      break
    end

    -- Move up one directory
    root_dir = vim.fn.fnamemodify(root_dir, ":h")
  end

  return root_dir
end

local function extract_content_after_frontmatter(content)
  local frontmatter_end = 0

  local frontmatter_at_start = content[1] and (content[1] == "---" or content[1] == "+++")
  if frontmatter_at_start then
    local delimiter = content[1]

    for i = 2, #content do
      if content[i] == delimiter then
        frontmatter_end = i
        break
      end
    end
  end

  if frontmatter_end > 0 then
    local result = {}
    for i = frontmatter_end + 1, #content do
      table.insert(result, content[i])
    end
    return result
  end

  -- If no frontmatter was found, return the original content
  return content
end

local function parse_glob_patterns(content)
  local patterns = {}
  local in_frontmatter = false

  for _, line in ipairs(content) do
    if line:match("^%-%-%-$") then
      if in_frontmatter then
        break
      else
        in_frontmatter = true
      end
    elseif in_frontmatter then
      local globs = line:gsub("^%s*(.-)%s*$", "%1"):match("^globs:%s*(.+)$")
      if globs then
        -- Handle array format: globs: ["pattern1", "pattern2"]
        if globs:match("^%[.+%]$") then
          -- Remove [ and ]
          local globs_content = globs:sub(2, -2)
          -- handles both ' and "
          for pattern_match in globs_content:gmatch("[\"']([^\"']+)[\"']") do
            table.insert(patterns, pattern_match)
          end
        else
          -- Split by comma and trim whitespace/quotes
          for pattern in globs:gmatch("[^,]+") do
            local clean_glob = pattern:gsub("^%s*[\"']?(.-)[\"']?%s*$", "%1")
            table.insert(patterns, clean_glob)
          end
        end
        break
      end
    end
  end

  return patterns
end

--- Get the content of a context file
---@param file string The path to the context file
---@param content string[] The content of the context file
local function to_context_file(file, content)
  local patterns = parse_glob_patterns(content)
  local filtered_content = extract_content_after_frontmatter(content)
  return { file = file, patterns = patterns, content = filtered_content }
end

--- Scans a directory for context files and extracts their patterns and content
--- @param context_dir string The directory path to scan for context files
--- @return ContextFiles.ContextFile[] array of context files found
local function scan_local_files(context_dir)
  local files = {}
  local scan_files = vim.fn.globpath(context_dir, "**/*", false, true)

  for _, file in ipairs(scan_files) do
    if vim.fn.isdirectory(file) == 0 then
      local content = vim.fn.readfile(file)
      table.insert(files, to_context_file(file, content))
    end
  end

  return files
end

-- Get the content of files whose patterns match the current file
---@param context_files ContextFiles.ContextFile[] Array of  files found
---@param file_name_from_root_dir string The name of the current file relative to the project root
---@return ContextFiles.ContextFile[] Array of  files whose patterns match the current file
local function get_matching_context_files(context_files, file_name_from_root_dir)
  local files = {}

  for _, file_entry in ipairs(context_files) do
    if file_entry.patterns then
      if #file_entry.patterns == 0 then
        table.insert(files, file_entry)
      end

      for _, pattern in ipairs(file_entry.patterns) do
        local lpg = vim.glob.to_lpeg(pattern)
        local is_match = lpg:match(file_name_from_root_dir)
        if is_match then
          table.insert(files, file_entry)
        end
      end
    end
  end

  return files
end

---@param gist_id string The ID of the gist to fetch_gist_files
---@param source_file_name string The name of the source file
---@return ContextFiles.ContextFile[] Array of context files found
local function fetch_gist_files(gist_id, source_file_name)
  local url = "https://api.github.com/gists/" .. gist_id
  local response = vim.fn.systemlist({ "curl", "-s", url })
  local gist_content = table.concat(response, "\n")
  local body = vim.fn.json_decode(gist_content)

  local files = {}

  if body and body.files then
    for _, file_data in pairs(body.files) do
      local file_content = vim.fn.split(file_data.content, "\n")
      local file = to_context_file(source_file_name, file_content)
      table.insert(files, file)
    end
  else
    print("Error: Invalid gist response or no files found")
  end

  return files
end

---@param gist_ids string[] Array of gist IDs to fetch context files from
---@param source_file_name string The name of the source file
---@return ContextFiles.ContextFile[] Array of files found
local function get_gist_context_files(gist_ids, source_file_name)
  local gists = {}

  for _, gist_id in ipairs(gist_ids) do
    local files = fetch_gist_files(gist_id, source_file_name)
    for _, file in ipairs(files) do
      table.insert(gists, file)
    end
  end

  return gists
end

---@class ContextFiles.Opts
---@field context_dir? string Directory containing  files (default: ".cursor/rules")
---@field root_markers? string[] Markers to identify the project root (default: {".git"})
---@field gist_ids? string[] Array of gist IDs to fetch context files from (default: {})
---@field enable_local? boolean Enable local scan of  files (default: true)

---@class ContextFiles.ContextFile
---@field file string Path to the file
---@field patterns string[] Array of glob patterns parsed from the file
---@field content string[] Array of lines from the file with frontmatter removed

---@param file string Path to the current file
---@param opts? ContextFiles.Opts Configuration options
---@return ContextFiles.ContextFile[] Array of  files found
function M.get_context_files(file, opts)
  opts = vim.tbl_deep_extend("force", M.OPTS_DEFAULTS, opts or {})

  local root_dir = find_root_dir(file, opts.root_markers)
  local absolute_context_dir = root_dir .. "/" .. opts.context_dir
  local has_gists = #opts.gist_ids > 0

  if vim.fn.isdirectory(absolute_context_dir) == 0 and opts.enable_local and not has_gists then
    vim.api.nvim_err_writeln("Context directory '" .. opts.context_dir .. "' does not exist")
    return {}
  end

  local files = {}

  if opts.enable_local then
    files = scan_local_files(absolute_context_dir)
  end

  local file_name_from_root_dir = file:sub(#root_dir + 2)

  if #opts.gist_ids == 0 then
    return get_matching_context_files(files, file_name_from_root_dir)
  end

  local gist_context_files = get_gist_context_files(opts.gist_ids, file_name_from_root_dir)
  for _, gist_file in pairs(gist_context_files) do
    table.insert(files, gist_file)
  end

  return get_matching_context_files(files, file_name_from_root_dir)
end

---@class ContextFiles.FormatOpts
---@field prefix? string The prefix to use for the formatted string
---@field suffix? string The suffix to use for the formatted string
---@field separator? string The separator to use between each file content

---@param context_files ContextFiles.ContextFile[] Array of context files found
---@param opts ContextFiles.FormatOpts? Options for formatting the output
function M.format_multiple_files(context_files, opts)
  opts = vim.tbl_deep_extend("force", M.FORMAT_DEFAULTS, opts or {})

  if #context_files == 0 then
    return ""
  end

  local contents = {}
  for _, context_file in ipairs(context_files) do
    local file_content = table.concat(context_file.content, "\n")
    table.insert(contents, file_content)
  end

  local prefix = opts.prefix
  if type(opts.prefix) == "function" then
    prefix = opts.prefix()
  end

  local suffix = opts.suffix
  if type(opts.suffix) == "function" then
    suffix = opts.suffix()
  end

  return prefix .. table.concat(contents, opts.separator) .. suffix
end

---@param context_file ContextFiles.ContextFile the context file to format
---@param opts ContextFiles.FormatOpts? Options for formatting the output
function M.format(context_file, opts)
  opts = vim.tbl_deep_extend("force", M.FORMAT_DEFAULTS, opts or {})

  local content = table.concat(context_file.content, "\n")

  local prefix = opts.prefix
  if type(opts.prefix) == "function" then
    prefix = opts.prefix(context_file)
  end

  local suffix = opts.suffix
  if type(opts.suffix) == "function" then
    suffix = opts.suffix(context_file)
  end

  return prefix .. content .. suffix
end

-- FOR TESTING PURPOSES ONLY
M._test_parse_glob_patterns = parse_glob_patterns
M._test_extract_content_after_frontmatter = extract_content_after_frontmatter
M._test_get_matching_context_files = get_matching_context_files

return M
