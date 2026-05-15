local M = {}

local ALLOWED_TYPE = {
  CODE = true,
  SPEC = true,
  DESIGN = true,
  RESEARCH = true,
  PROTOCOL = true,
  CANON = true,
  DOCS = true,
  TEST = true,
}

local ALLOWED_STRENGTH = {
  weak = true,
  medium = true,
  strong = true,
}

local ALLOWED_SCOPE = {
  concept = true,
  prototype = true,
  runnable = true,
  production_like = true,
  production = true,
}

function M.validate(items)
  if type(items) ~= "table" then
    return false, "evidence batch must be a table"
  end

  for i = 1, #items do
    local item = items[i]
    if type(item) ~= "table" then
      return false, "evidence[" .. i .. "] must be a table"
    end
    if type(item.evidence_id) ~= "string" or item.evidence_id == "" then
      return false, "evidence[" .. i .. "] missing evidence_id"
    end
    if type(item.statement) ~= "string" or item.statement == "" then
      return false, "evidence[" .. i .. "] missing statement"
    end
    if type(item.source_artifacts) ~= "table" or #item.source_artifacts == 0 then
      return false, "evidence[" .. i .. "] missing source_artifacts"
    end
    if type(item.source_spans) ~= "string" or item.source_spans == "" then
      return false, "evidence[" .. i .. "] missing source_spans"
    end
    if type(item.evidence_type) ~= "string" or not ALLOWED_TYPE[item.evidence_type] then
      return false, "evidence[" .. i .. "] invalid evidence_type"
    end
    if type(item.strength) ~= "string" or not ALLOWED_STRENGTH[item.strength] then
      return false, "evidence[" .. i .. "] invalid strength"
    end
    if type(item.scope) ~= "string" or not ALLOWED_SCOPE[item.scope] then
      return false, "evidence[" .. i .. "] invalid scope"
    end
    if type(item.supports_skills) ~= "table" then
      return false, "evidence[" .. i .. "] missing supports_skills"
    end
    if type(item.limitations) ~= "table" then
      return false, "evidence[" .. i .. "] missing limitations"
    end
    if type(item.confidence) ~= "number" then
      return false, "evidence[" .. i .. "] missing confidence"
    end
  end

  return true
end

return M
