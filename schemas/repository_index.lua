local M = {}

function M.validate(items)
  if type(items) ~= "table" then
    return false, "repository index must be a table"
  end

  for i = 1, #items do
    local item = items[i]
    if type(item) ~= "table" then
      return false, "repository[" .. i .. "] must be a table"
    end
    if type(item.repo_id) ~= "string" or item.repo_id == "" then
      return false, "repository[" .. i .. "] missing repo_id"
    end
    if type(item.local_path) ~= "string" or item.local_path == "" then
      return false, "repository[" .. i .. "] missing local_path"
    end
    if type(item.repo_name) ~= "string" or item.repo_name == "" then
      return false, "repository[" .. i .. "] missing repo_name"
    end
  end

  return true
end

return M
