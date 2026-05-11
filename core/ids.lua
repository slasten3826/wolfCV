local M = {}

local function slug(value)
  value = tostring(value):lower()
  value = value:gsub("[^%w]+", "_")
  value = value:gsub("^_+", "")
  value = value:gsub("_+$", "")
  if value == "" then
    value = "item"
  end
  return value
end

function M.repo_id(repo_name)
  return "repo_" .. slug(repo_name)
end

function M.artifact_id(repo_name, rel_path)
  return "art_" .. slug(repo_name) .. "_" .. slug(rel_path)
end

return M
