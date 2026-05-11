local M = {}

local ALLOWED = {
  CODE = true,
  SPEC = true,
  DESIGN = true,
  RESEARCH = true,
  PROTOCOL = true,
  CANON = true,
  META = true,
  PHILOSOPHY = true,
  DOCS = true,
  INDEX = true,
  MEDIA = true,
  DRAFT = true,
  CONFIG = true,
  TEST = true,
}

function M.validate(items)
  if type(items) ~= "table" then
    return false, "classified artifact batch must be a table"
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
    if type(item["class"]) ~= "string" or not ALLOWED[item["class"]] then
      return false, "artifact[" .. i .. "] has invalid class"
    end
    if type(item.summary) ~= "string" or item.summary == "" then
      return false, "artifact[" .. i .. "] missing summary"
    end
    if type(item.confidence) ~= "number" then
      return false, "artifact[" .. i .. "] missing confidence"
    end
    if type(item.role_tags) ~= "table" then
      return false, "artifact[" .. i .. "] missing role_tags"
    end
  end

  return true
end

return M
