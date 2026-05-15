local M = {}

local ALLOWED_STATUS = {
  SUPPORTED = true,
  PARTIALLY_SUPPORTED = true,
  RITUAL_TRANSLATION = true,
  UNSUPPORTED = true,
  FORBIDDEN = true,
}

function M.validate(items)
  if type(items) ~= "table" then
    return false, "guard result batch must be a table"
  end

  for i = 1, #items do
    local item = items[i]
    if type(item) ~= "table" then
      return false, "guard_result[" .. i .. "] must be a table"
    end
    if type(item.guard_id) ~= "string" or item.guard_id == "" then
      return false, "guard_result[" .. i .. "] missing guard_id"
    end
    if type(item.claim_id) ~= "string" or item.claim_id == "" then
      return false, "guard_result[" .. i .. "] missing claim_id"
    end
    if type(item.status) ~= "string" or not ALLOWED_STATUS[item.status] then
      return false, "guard_result[" .. i .. "] invalid status"
    end
    if type(item.reason) ~= "string" or item.reason == "" then
      return false, "guard_result[" .. i .. "] missing reason"
    end
    if type(item.recommended_wording) ~= "string" or item.recommended_wording == "" then
      return false, "guard_result[" .. i .. "] missing recommended_wording"
    end
    if type(item.blocking_evidence_ids) ~= "table" then
      return false, "guard_result[" .. i .. "] missing blocking_evidence_ids"
    end
    if type(item.missing_evidence) ~= "table" then
      return false, "guard_result[" .. i .. "] missing missing_evidence"
    end
    if type(item.review_required) ~= "boolean" then
      return false, "guard_result[" .. i .. "] missing review_required"
    end
  end

  return true
end

return M
