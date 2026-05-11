local M = {}

local SEP = "/"

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.shell_quote(value)
  return shell_quote(value)
end

function M.join(...)
  local parts = { ... }
  local out = {}
  for i = 1, #parts do
    local p = tostring(parts[i])
    if p ~= "" then
      out[#out + 1] = p
    end
  end
  local joined = table.concat(out, SEP)
  joined = joined:gsub("/+", "/")
  return joined
end

function M.abspath(path)
  local handle = io.popen("cd " .. shell_quote(path) .. " 2>/dev/null && pwd")
  if handle then
    local value = handle:read("*a")
    handle:close()
    value = trim(value)
    if value ~= "" then
      return value
    end
  end

  local pwd = io.popen("pwd")
  local base = pwd and trim(pwd:read("*a")) or "."
  if pwd then
    pwd:close()
  end
  if path:sub(1, 1) == "/" then
    return path
  end
  return M.join(base, path)
end

function M.exists(path)
  local handle = io.open(path, "rb")
  if handle then
    handle:close()
    return true
  end
  local ok = os.execute("test -e " .. shell_quote(path) .. " >/dev/null 2>&1")
  return ok == true or ok == 0
end

function M.is_dir(path)
  local ok = os.execute("test -d " .. shell_quote(path) .. " >/dev/null 2>&1")
  return ok == true or ok == 0
end

function M.mkdir_p(path)
  local ok = os.execute("mkdir -p " .. shell_quote(path) .. " >/dev/null 2>&1")
  if not (ok == true or ok == 0) then
    error("failed to create directory: " .. path)
  end
end

function M.read_file(path)
  local handle = assert(io.open(path, "rb"))
  local content = handle:read("*a")
  handle:close()
  return content
end

function M.write_file(path, content)
  local parent = path:match("^(.*)/[^/]+$")
  if parent and parent ~= "" then
    M.mkdir_p(parent)
  end
  local handle = assert(io.open(path, "wb"))
  handle:write(content)
  handle:close()
end

local function run_lines(command)
  local pipe = assert(io.popen(command))
  local lines = {}
  for line in pipe:lines() do
    lines[#lines + 1] = line
  end
  pipe:close()
  return lines
end

function M.list_repo_files(path)
  local quoted = shell_quote(path)
  local lines = run_lines("cd " .. quoted .. " && rg --files . 2>/dev/null")
  if #lines == 0 then
    lines = run_lines("cd " .. quoted .. " && find . -type f | sed 's#^./##' 2>/dev/null")
  end
  return lines
end

function M.git_branch(path)
  local pipe = io.popen("cd " .. shell_quote(path) .. " && git rev-parse --abbrev-ref HEAD 2>/dev/null")
  if not pipe then
    return "unknown"
  end
  local value = trim(pipe:read("*a") or "")
  pipe:close()
  return value ~= "" and value or "unknown"
end

function M.git_commit(path)
  local pipe = io.popen("cd " .. shell_quote(path) .. " && git rev-parse HEAD 2>/dev/null")
  if not pipe then
    return "HEAD"
  end
  local value = trim(pipe:read("*a") or "")
  pipe:close()
  return value ~= "" and value or "HEAD"
end

return M
