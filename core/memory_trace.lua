local fs = require("core.fs")

local M = {}

local function enabled()
  local value = os.getenv("WOLFCV_MEMORY_TRACE")
  return value == "1" or value == "true" or value == "yes"
end

local function proc_status_value(key)
  local ok, content = pcall(fs.read_file, "/proc/self/status")
  if not ok then
    return nil
  end

  local value = content:match(key .. ":%s+(%d+)%s+kB")
  if not value then
    return nil
  end

  return tonumber(value)
end

local function now_utc()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

function M.log(out_dir, label, fields)
  if not enabled() then
    return
  end

  local lines = {
    string.format("[%s] %s", now_utc(), label),
    string.format("  lua_heap_kb=%d", math.floor(collectgarbage("count"))),
  }

  local vmrss = proc_status_value("VmRSS")
  local vmswap = proc_status_value("VmSwap")
  local vmsize = proc_status_value("VmSize")

  if vmrss then
    lines[#lines + 1] = string.format("  vmrss_kb=%d", vmrss)
  end
  if vmswap then
    lines[#lines + 1] = string.format("  vmswap_kb=%d", vmswap)
  end
  if vmsize then
    lines[#lines + 1] = string.format("  vmsize_kb=%d", vmsize)
  end

  if type(fields) == "table" then
    local keys = {}
    for key, _ in pairs(fields) do
      keys[#keys + 1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
      lines[#lines + 1] = string.format("  %s=%s", key, tostring(fields[key]))
    end
  end

  lines[#lines + 1] = ""
  local path = fs.join(out_dir, "memory_trace.log")
  local previous = ""
  if fs.exists(path) then
    previous = fs.read_file(path)
  end
  fs.write_file(path, previous .. table.concat(lines, "\n"))
end

return M
