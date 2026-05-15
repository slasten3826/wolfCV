local M = {}

local function push(lines, value)
  lines[#lines + 1] = value
end

function M.render(results)
  local lines = {}
  push(lines, "# Evidence Guard Report")
  push(lines, "")

  for _, item in ipairs(results or {}) do
    push(lines, "- claim_id: " .. item.claim_id)
    push(lines, "  status: " .. item.status)
    push(lines, "  review_required: " .. tostring(item.review_required))
    push(lines, "  reason: " .. item.reason)
    push(lines, "  recommended_wording: " .. item.recommended_wording)
    if item.blocking_evidence_ids and #item.blocking_evidence_ids > 0 then
      push(lines, "  blocking_evidence_ids: " .. table.concat(item.blocking_evidence_ids, ", "))
    end
    if item.missing_evidence and #item.missing_evidence > 0 then
      push(lines, "  missing_evidence: " .. table.concat(item.missing_evidence, ", "))
    end
    push(lines, "")
  end

  return table.concat(lines, "\n") .. "\n"
end

return M
