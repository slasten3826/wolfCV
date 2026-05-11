local M = {}

local function is_array(value)
  if type(value) ~= "table" then
    return false
  end
  local count = 0
  for k, _ in pairs(value) do
    if type(k) ~= "number" then
      return false
    end
    if k <= 0 or k ~= math.floor(k) then
      return false
    end
    count = count + 1
  end
  for i = 1, count do
    if value[i] == nil then
      return false
    end
  end
  return true
end

local function escape_str(value)
  value = value:gsub("\\", "\\\\")
  value = value:gsub("\"", "\\\"")
  value = value:gsub("\n", "\\n")
  value = value:gsub("\r", "\\r")
  value = value:gsub("\t", "\\t")
  return "\"" .. value .. "\""
end

local function encode_value(value, indent, level)
  local kind = type(value)
  if kind == "nil" then
    return "null"
  elseif kind == "boolean" then
    return value and "true" or "false"
  elseif kind == "number" then
    return tostring(value)
  elseif kind == "string" then
    return escape_str(value)
  elseif kind ~= "table" then
    error("unsupported json type: " .. kind)
  end

  local pad = string.rep(indent, level)
  local next_pad = string.rep(indent, level + 1)

  if is_array(value) then
    if #value == 0 then
      return "[]"
    end
    local parts = {}
    for i = 1, #value do
      parts[#parts + 1] = next_pad .. encode_value(value[i], indent, level + 1)
    end
    return "[\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "]"
  end

  local keys = {}
  for key, _ in pairs(value) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

  if #keys == 0 then
    return "{}"
  end

  local parts = {}
  for _, key in ipairs(keys) do
    parts[#parts + 1] = next_pad .. escape_str(tostring(key)) .. ": " .. encode_value(value[key], indent, level + 1)
  end
  return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
end

function M.encode_pretty(value)
  return encode_value(value, "  ", 0)
end

local function decode_error(pos, msg)
  error("json decode error at " .. tostring(pos) .. ": " .. msg)
end

local function skip_ws(str, pos)
  while true do
    local ch = str:sub(pos, pos)
    if ch == " " or ch == "\n" or ch == "\r" or ch == "\t" then
      pos = pos + 1
    else
      return pos
    end
  end
end

local parse_value

local function parse_string(str, pos)
  pos = pos + 1
  local out = {}
  while pos <= #str do
    local ch = str:sub(pos, pos)
    if ch == "\"" then
      return table.concat(out), pos + 1
    elseif ch == "\\" then
      local esc = str:sub(pos + 1, pos + 1)
      if esc == "\"" or esc == "\\" or esc == "/" then
        out[#out + 1] = esc
        pos = pos + 2
      elseif esc == "b" then
        out[#out + 1] = "\b"
        pos = pos + 2
      elseif esc == "f" then
        out[#out + 1] = "\f"
        pos = pos + 2
      elseif esc == "n" then
        out[#out + 1] = "\n"
        pos = pos + 2
      elseif esc == "r" then
        out[#out + 1] = "\r"
        pos = pos + 2
      elseif esc == "t" then
        out[#out + 1] = "\t"
        pos = pos + 2
      else
        decode_error(pos, "unsupported escape")
      end
    else
      out[#out + 1] = ch
      pos = pos + 1
    end
  end
  decode_error(pos, "unterminated string")
end

local function parse_number(str, pos)
  local start = pos
  local ch = str:sub(pos, pos)
  if ch == "-" then
    pos = pos + 1
  end
  while str:sub(pos, pos):match("%d") do
    pos = pos + 1
  end
  if str:sub(pos, pos) == "." then
    pos = pos + 1
    while str:sub(pos, pos):match("%d") do
      pos = pos + 1
    end
  end
  local exp = str:sub(pos, pos)
  if exp == "e" or exp == "E" then
    pos = pos + 1
    local sign = str:sub(pos, pos)
    if sign == "+" or sign == "-" then
      pos = pos + 1
    end
    while str:sub(pos, pos):match("%d") do
      pos = pos + 1
    end
  end
  local value = tonumber(str:sub(start, pos - 1))
  if value == nil then
    decode_error(start, "invalid number")
  end
  return value, pos
end

local function parse_array(str, pos)
  pos = pos + 1
  local arr = {}
  pos = skip_ws(str, pos)
  if str:sub(pos, pos) == "]" then
    return arr, pos + 1
  end
  while true do
    local value
    value, pos = parse_value(str, pos)
    arr[#arr + 1] = value
    pos = skip_ws(str, pos)
    local ch = str:sub(pos, pos)
    if ch == "]" then
      return arr, pos + 1
    elseif ch ~= "," then
      decode_error(pos, "expected ',' or ']'")
    end
    pos = skip_ws(str, pos + 1)
  end
end

local function parse_object(str, pos)
  pos = pos + 1
  local obj = {}
  pos = skip_ws(str, pos)
  if str:sub(pos, pos) == "}" then
    return obj, pos + 1
  end
  while true do
    if str:sub(pos, pos) ~= "\"" then
      decode_error(pos, "expected string key")
    end
    local key
    key, pos = parse_string(str, pos)
    pos = skip_ws(str, pos)
    if str:sub(pos, pos) ~= ":" then
      decode_error(pos, "expected ':'")
    end
    pos = skip_ws(str, pos + 1)
    local value
    value, pos = parse_value(str, pos)
    obj[key] = value
    pos = skip_ws(str, pos)
    local ch = str:sub(pos, pos)
    if ch == "}" then
      return obj, pos + 1
    elseif ch ~= "," then
      decode_error(pos, "expected ',' or '}'")
    end
    pos = skip_ws(str, pos + 1)
  end
end

function parse_value(str, pos)
  pos = skip_ws(str, pos)
  local ch = str:sub(pos, pos)
  if ch == "\"" then
    return parse_string(str, pos)
  elseif ch == "{" then
    return parse_object(str, pos)
  elseif ch == "[" then
    return parse_array(str, pos)
  elseif ch == "-" or ch:match("%d") then
    return parse_number(str, pos)
  elseif str:sub(pos, pos + 3) == "true" then
    return true, pos + 4
  elseif str:sub(pos, pos + 4) == "false" then
    return false, pos + 5
  elseif str:sub(pos, pos + 3) == "null" then
    return nil, pos + 4
  end
  decode_error(pos, "unexpected token")
end

function M.decode(text)
  local value, pos = parse_value(text, 1)
  pos = skip_ws(text, pos)
  if pos <= #text then
    decode_error(pos, "trailing data")
  end
  return value
end

return M
