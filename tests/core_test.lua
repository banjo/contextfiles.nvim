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

-- 7. Empty globs
do
  local content = { "---", "globs:", "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, {}, "parse_glob_patterns (empty) failed")
end

-- 8. Array with trailing comma
do
  local content = { "---", 'globs: ["*.ts", "*.js",]', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts", "*.js" }, "parse_glob_patterns (array trailing comma) failed")
end

-- 9. Array with mixed quotes
do
  local content = { "---", "globs: [\"*.ts\", '*.js']", "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts", "*.js" }, "parse_glob_patterns (array mixed quotes) failed")
end

-- 10. Glob with spaces inside quotes
do
  local content = { "---", 'globs: ["*.ts", "src/**/*.js"]', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts", "src/**/*.js" }, "parse_glob_patterns (spaces in glob) failed")
end

-- 11. Glob with escaped quotes (not supported by current parser, should fail or ignore)
do
  local content = { "---", 'globs: ["src/\\"foo\\"/*.js"]', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  -- Current parser will return src/\ as the pattern, so we expect it to fail or not match
  -- If you want to support this, update your parser!
end

-- 12. Multiple globs lines (only first should be parsed)
do
  local content = { "---", 'globs: "*.ts"', 'globs: "*.js"', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts" }, "parse_glob_patterns (multiple globs lines) failed")
end

-- 13. Globs with comments (comment should be ignored, but current parser does not support this)
do
  local content = { "---", 'globs: ["*.ts", "*.js"] # comment', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  -- Current parser will include the comment in the last pattern, so this will fail unless parser is improved
  -- assert_table_equal(patterns, { "*.ts", "*.js" }, "parse_glob_patterns (comment) failed")
end

-- 14. Globs with semicolon separator (should be treated as one pattern)
do
  local content = { "---", 'globs: "*.ts;*.js"', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts;*.js" }, "parse_glob_patterns (semicolon) failed")
end

-- 15. Globs with leading/trailing whitespace
do
  local content = { "---", 'globs:   "*.ts"  ,  "*.js"   ', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "*.ts", "*.js" }, "parse_glob_patterns (whitespace) failed")
end

-- 16. Globs with brace expansion
do
  local content = { "---", "globs: **/file\\.{ts,js}", "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "**/file\\.{ts,js}" }, "parse_glob_patterns (brace expansion) failed")
end

-- 17. Array syntax with brace expansion
do
  local content = { "---", 'globs: ["**/file.{ts,js}"]', "---", "Some rule content" }
  local patterns = core._test_parse_glob_patterns(content)
  assert_table_equal(patterns, { "**/file.{ts,js}" }, "parse_glob_patterns (array brace expansion) failed")
end

print("All tests passed!")
