local M = {}

local ALLOWED = {
  read_now = true,
  read_if_needed = true,
  skip = true,
}

local function require_string(item, key)
  return type(item[key]) == "string" and item[key] ~= ""
end

local function require_number(item, key)
  return type(item[key]) == "number"
end

local function validate_item(item)
  if type(item) ~= "table" then
    return false, "batch selection item must be a table"
  end
  if not require_string(item, "batch_id") then
    return false, "batch selection item missing batch_id"
  end
  if not require_string(item, "decision") then
    return false, "batch selection item missing decision"
  end
  if not ALLOWED[item.decision] then
    return false, "batch selection item has invalid decision"
  end
  if not require_string(item, "reason") then
    return false, "batch selection item missing reason"
  end
  if not require_string(item, "target_surface") then
    return false, "batch selection item missing target_surface"
  end
  if not require_number(item, "confidence") then
    return false, "batch selection item missing confidence"
  end
  return true
end

function M.validate(items)
  if type(items) ~= "table" then
    return false, "batch selection must be an array"
  end
  for _, item in ipairs(items) do
    local ok, err = validate_item(item)
    if not ok then
      return false, err
    end
  end
  return true
end

return M
