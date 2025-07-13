package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
local core = require("contextfiles.core")

local function table_equal(t1, t2)
  if #t1 ~= #t2 then return false end
  for i = 1, #t1 do
    if t1[i] ~= t2[i] then return false end
  end
  return true
end

local function run_test(name, input, expected)
  local result = core._test_parse_glob_patterns(input)
  local ok = table_equal(result, expected)
  if ok then
    print("[PASS] " .. name)
  else
    print("[FAIL] " .. name)
    print("  Input:    " .. vim.inspect(input))
    print("  Expected: " .. vim.inspect(expected))
    print("  Got:      " .. vim.inspect(result))
  end
end

local tests = {
  {
    name = "Comma-separated globs",
    input = { "---", "globs: *.ts,*.tsx,*.js", "---", "Some rule content" },
    expected = { "*.ts", "*.tsx", "*.js" },
  },
  {
    name = "Array globs",
    input = { "---", 'globs: ["**/*.md", "*.txt"]', "---", "Some rule content" },
    expected = { "**/*.md", "*.txt" },
  },
  {
    name = "Single glob",
    input = { "---", 'globs: "*.lua"', "---", "Some rule content" },
    expected = { "*.lua" },
  },
  {
    name = "No globs",
    input = { "---", "no_globs_here: true", "---", "Some rule content" },
    expected = {},
  },
  {
    name = "Array with single quotes",
    input = { "---", "globs: ['*.ts','*.js']", "---", "Some rule content" },
    expected = { "*.ts", "*.js" },
  },
  {
    name = "Array with spaces",
    input = { "---", 'globs: [ "*.ts" , "*.js" ]', "---", "Some rule content" },
    expected = { "*.ts", "*.js" },
  },
  {
    name = "Empty globs",
    input = { "---", "globs:", "---", "Some rule content" },
    expected = {},
  },
  {
    name = "Array with trailing comma",
    input = { "---", 'globs: ["*.ts", "*.js",]', "---", "Some rule content" },
    expected = { "*.ts", "*.js" },
  },
  {
    name = "Array with mixed quotes",
    input = { "---", 'globs: ["*.ts", \'*.js\']', "---", "Some rule content" },
    expected = { "*.ts", "*.js" },
  },
  {
    name = "Glob with spaces inside quotes",
    input = { "---", 'globs: ["*.ts", "src/**/*.js"]', "---", "Some rule content" },
    expected = { "*.ts", "src/**/*.js" },
  },
  {
    name = "Multiple globs lines (only first parsed)",
    input = { "---", 'globs: "*.ts"', 'globs: "*.js"', "---", "Some rule content" },
    expected = { "*.ts" },
  },
  {
    name = "Globs with semicolon separator",
    input = { "---", 'globs: "*.ts;*.js"', "---", "Some rule content" },
    expected = { "*.ts;*.js" },
  },
  {
    name = "Globs with leading/trailing whitespace",
    input = { "---", 'globs:   "*.ts"  ,  "*.js"   ', "---", "Some rule content" },
    expected = { "*.ts", "*.js" },
  },
  {
    name = "Globs with brace expansion",
    input = { "---", "globs: **/file.{ts,js}", "---", "Some rule content" },
    expected = { "**/file.{ts,js}" },
  },
  {
    name = "Array syntax with brace expansion",
    input = { "---", 'globs: ["**/file.{ts,js}"]', "---", "Some rule content" },
    expected = { "**/file.{ts,js}" },
  },
  -- Robust edge cases:
  {
    name = "Comma inside braces",
    input = { "---", "globs: foo,{bar,baz},qux", "---", "Some rule content" },
    expected = { "foo", "{bar,baz}", "qux" },
  },
  {
    name = "Comma inside double quotes (stripped)",
    input = { "---", 'globs: "foo,bar",baz', "---", "Some rule content" },
    expected = { "foo,bar", "baz" },
  },
  {
    name = "Comma inside single quotes (stripped)",
    input = { "---", "globs: 'foo,bar',baz", "---", "Some rule content" },
    expected = { "foo,bar", "baz" },
  },
  {
    name = "Comma inside character class",
    input = { "---", "globs: foo[ab,cd],bar", "---", "Some rule content" },
    expected = { "foo[ab,cd]", "bar" },
  },
  {
    name = "Nested braces and brackets",
    input = { "---", "globs: foo,{bar,[baz,qux]},other", "---", "Some rule content" },
    expected = { "foo", "{bar,[baz,qux]}", "other" },
  },
}

for _, test in ipairs(tests) do
  run_test(test.name, test.input, test.expected)
end
