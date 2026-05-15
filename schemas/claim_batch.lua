local M = {}

local ALLOWED_SUPPORT = {
  SUPPORTED = true,
  PARTIALLY_SUPPORTED = true,
  RITUAL_TRANSLATION = true,
  UNSUPPORTED = true,
  FORBIDDEN = true,
}

local ALLOWED_RISK = {
  low = true,
  medium = true,
  high = true,
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
    return false, "claim batch must be a table"
  end

  for i = 1, #items do
    local item = items[i]
    if type(item) ~= "table" then
      return false, "claim[" .. i .. "] must be a table"
    end
    if type(item.claim_id) ~= "string" or item.claim_id == "" then
      return false, "claim[" .. i .. "] missing claim_id"
    end
    if type(item.text) ~= "string" or item.text == "" then
      return false, "claim[" .. i .. "] missing text"
    end
    if type(item.normalized_skill_tags) ~= "table" then
      return false, "claim[" .. i .. "] missing normalized_skill_tags"
    end
    if type(item.support_level) ~= "string" or not ALLOWED_SUPPORT[item.support_level] then
      return false, "claim[" .. i .. "] invalid support_level"
    end
    if type(item.supporting_evidence_ids) ~= "table" then
      return false, "claim[" .. i .. "] missing supporting_evidence_ids"
    end
    if type(item.risk_level) ~= "string" or not ALLOWED_RISK[item.risk_level] then
      return false, "claim[" .. i .. "] invalid risk_level"
    end
    if type(item.scope) ~= "string" or not ALLOWED_SCOPE[item.scope] then
      return false, "claim[" .. i .. "] invalid scope"
    end
    if type(item.safe_for_cv) ~= "boolean" then
      return false, "claim[" .. i .. "] missing safe_for_cv"
    end
    if type(item.safer_wording) ~= "string" or item.safer_wording == "" then
      return false, "claim[" .. i .. "] missing safer_wording"
    end
    if item.forbidden_reason ~= nil and type(item.forbidden_reason) ~= "string" then
      return false, "claim[" .. i .. "] invalid forbidden_reason"
    end
  end

  return true
end

return M
