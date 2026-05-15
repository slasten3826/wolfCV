local M = {}

local function push(lines, value)
  lines[#lines + 1] = value
end

local function join_list(items)
  if not items or #items == 0 then
    return ""
  end
  return table.concat(items, ", ")
end

function M.render(evidence, claims)
  local lines = {}
  push(lines, "# MachineCV")
  push(lines, "")
  push(lines, "Machine-facing truth layer.")
  push(lines, "")

  push(lines, "## Claims")
  push(lines, "")
  for _, claim in ipairs(claims) do
    push(lines, "- " .. claim.text)
    push(lines, "  support_level: " .. claim.support_level)
    push(lines, "  scope: " .. claim.scope)
    push(lines, "  risk: " .. claim.risk_level)
    push(lines, "  safe_for_cv: " .. tostring(claim.safe_for_cv))
    push(lines, "  skills: " .. join_list(claim.normalized_skill_tags))
    push(lines, "  evidence_ids: " .. join_list(claim.supporting_evidence_ids))
    if claim.forbidden_reason and claim.forbidden_reason ~= "" then
      push(lines, "  forbidden_reason: " .. claim.forbidden_reason)
    end
    push(lines, "  safer_wording: " .. claim.safer_wording)
    push(lines, "")
  end

  push(lines, "## Evidence")
  push(lines, "")
  for _, item in ipairs(evidence) do
    push(lines, "- " .. item.statement)
    push(lines, "  type: " .. item.evidence_type)
    push(lines, "  strength: " .. item.strength)
    push(lines, "  scope: " .. item.scope)
    push(lines, "  skills: " .. join_list(item.supports_skills))
    push(lines, "  source_artifacts: " .. join_list(item.source_artifacts))
    if item.limitations and #item.limitations > 0 then
      push(lines, "  limitations: " .. join_list(item.limitations))
    end
    push(lines, "")
  end

  return table.concat(lines, "\n") .. "\n"
end

return M
