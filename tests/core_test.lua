package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
local core = require("contextfiles.core")

local function assert_table_equal(t1, t2, msg)
  if #t1 ~= #t2 then
    error(msg or "Table lengths differ")
  end
  for i = 1, #t1 do
    if t1[i] ~= t2[i] then
      error(msg or ("Table values differ at index " .. i .. ": " .. tostring(t1[i]) .. " ~= " .. tostring(t2[i])))
    end
  end
end

-- 1. Comma-separated globs
do
  local content = { "---", "globs: *.ts,*.tsx,*.js", "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts", "*.tsx", "*.js" }, "parse_glob_patterns (comma) failed")
end

-- 2. Array globs
do
  local content = { "---", 'globs: ["**/*.md", "*.txt"]', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "**/*.md", "*.txt" }, "parse_glob_patterns (array) failed")
end

-- 3. Single glob
do
  local content = { "---", 'globs: "*.lua"', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.lua" }, "parse_glob_patterns (single) failed")
end

-- 4. No globs
do
  local content = { "---", "no_globs_here: true", "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, {}, "parse_glob_patterns (none) failed")
end

-- 5. Array with single quotes
do
  local content = { "---", "globs: ['*.ts','*.js']", "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts", "*.js" }, "parse_glob_patterns (array single quotes) failed")
end

-- 6. Array with spaces
do
  local content = { "---", 'globs: [ "*.ts" , "*.js" ]', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts", "*.js" }, "parse_glob_patterns (array spaces) failed")
end

print("All _test_parse_glob_patterns tests passed!")
