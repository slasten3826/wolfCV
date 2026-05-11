local M = {}

function M.validate(items)
  if type(items) ~= "table" then
    return false, "artifact batch must be a table"
  end

  for i = 1, #items do
    local item = items[i]
    if type(item) ~= "table" then
      return false, "artifact[" .. i .. "] must be a table"
    end
    if type(item.artifact_id) ~= "string" or item.artifact_id == "" then
      return false, "artifact[" .. i .. "] missing artifact_id"
    end
    if type(item.repo_id) ~= "string" or item.repo_id == "" then
      return false, "artifact[" .. i .. "] missing repo_id"
    end
    if type(item.path) ~= "string" or item.path == "" then
      return false, "artifact[" .. i .. "] missing path"
    end
    if type(item["class"]) ~= "string" or item["class"] == "" then
      return false, "artifact[" .. i .. "] missing class"
    end
  end

  return true
end

return M
