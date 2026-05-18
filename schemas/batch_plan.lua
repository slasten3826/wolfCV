local M = {}

local function require_string(item, key)
  return type(item[key]) == "string" and item[key] ~= ""
end

local function require_number(item, key)
  return type(item[key]) == "number"
end

local function require_array(item, key)
  return type(item[key]) == "table"
end

local function validate_item(item)
  if type(item) ~= "table" then
    return false, "batch plan item must be a table"
  end
  if not require_string(item, "batch_id") then
    return false, "batch plan item missing batch_id"
  end
  if not require_string(item, "repo_id") then
    return false, "batch plan item missing repo_id"
  end
  if not require_string(item, "repo_name") then
    return false, "batch plan item missing repo_name"
  end
  if not require_string(item, "cluster_id") then
    return false, "batch plan item missing cluster_id"
  end
  if not require_array(item, "artifact_ids") then
    return false, "batch plan item missing artifact_ids"
  end
  if not require_array(item, "representative_paths") then
    return false, "batch plan item missing representative_paths"
  end
  if not require_array(item, "class_mix") then
    return false, "batch plan item missing class_mix"
  end
  if not require_array(item, "signal_tags") then
    return false, "batch plan item missing signal_tags"
  end
  if not require_number(item, "artifact_count") then
    return false, "batch plan item missing artifact_count"
  end
  if not require_number(item, "estimated_chars") then
    return false, "batch plan item missing estimated_chars"
  end
  if not require_number(item, "planner_priority") then
    return false, "batch plan item missing planner_priority"
  end
  return true
end

function M.validate(items)
  if type(items) ~= "table" then
    return false, "batch plan must be an array"
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
