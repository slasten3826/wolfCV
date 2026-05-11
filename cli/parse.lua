local M = {}

local function take_value(args, index, flag)
  local value = args[index + 1]
  if not value or value:sub(1, 2) == "--" then
    error("missing value for " .. flag)
  end
  return value, index + 1
end

function M.parse(args)
  local command = args[1] or "help"
  local parsed = {
    command = command,
    repos = {},
    out = "./wolfcv-out",
    target = nil,
    notes = nil,
    forbidden_claims = nil,
    include = {},
    exclude = {},
    format = "json",
    verbose = false,
  }

  local i = 2
  while i <= #args do
    local token = args[i]

    if token == "--repos" then
      i = i + 1
      while i <= #args and args[i]:sub(1, 2) ~= "--" do
        parsed.repos[#parsed.repos + 1] = args[i]
        i = i + 1
      end
      i = i - 1
    elseif token == "--target" then
      parsed.target, i = take_value(args, i, token)
    elseif token == "--out" then
      parsed.out, i = take_value(args, i, token)
    elseif token == "--notes" then
      parsed.notes, i = take_value(args, i, token)
    elseif token == "--forbidden-claims" then
      parsed.forbidden_claims, i = take_value(args, i, token)
    elseif token == "--include" then
      local value
      value, i = take_value(args, i, token)
      parsed.include[#parsed.include + 1] = value
    elseif token == "--exclude" then
      local value
      value, i = take_value(args, i, token)
      parsed.exclude[#parsed.exclude + 1] = value
    elseif token == "--format" then
      parsed.format, i = take_value(args, i, token)
    elseif token == "--verbose" then
      parsed.verbose = true
    else
      error("unknown argument: " .. token)
    end

    i = i + 1
  end

  return parsed
end

return M
