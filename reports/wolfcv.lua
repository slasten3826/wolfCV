local M = {}

local ALLOWED_STATUS = {
  SUPPORTED = true,
  PARTIALLY_SUPPORTED = true,
  RITUAL_TRANSLATION = true,
}

local function push(lines, value)
  lines[#lines + 1] = value
end

local function safe_skill_blocks(draft)
  local out = {}
  local seen = {}
  for _, item in ipairs(draft.skill_blocks or {}) do
    if type(item) == "string" and item ~= "" and not seen[item] then
      out[#out + 1] = item
      seen[item] = true
    end
  end
  return out
end

local function safe_bullets(draft, guard_map)
  local out = {}
  for _, bullet in ipairs(draft.project_bullets or {}) do
    local claim_id = bullet.claim_ids and bullet.claim_ids[1] or nil
    local guard = claim_id and guard_map[claim_id] or nil
    if guard and ALLOWED_STATUS[guard.status] and not guard.review_required then
      out[#out + 1] = guard.recommended_wording
    end
  end
  return out
end

function M.render(vacancy_map, draft, guard_results)
  local lines = {}
  local guard_map = {}
  for _, item in ipairs(guard_results or {}) do
    guard_map[item.claim_id] = item
  end

  local bullets = safe_bullets(draft, guard_map)
  local skills = safe_skill_blocks(draft)

  push(lines, "# WolfCV")
  push(lines, "")
  push(lines, "Target role: " .. (draft.role_title or vacancy_map.title or "Target role"))
  push(lines, "")
  push(lines, "Evidence-backed projection for the target vacancy.")
  push(lines, "")

  if #skills > 0 then
    push(lines, "## Skills")
    push(lines, "")
    for _, item in ipairs(skills) do
      push(lines, "- " .. item)
    end
    push(lines, "")
  end

  push(lines, "## Highlights")
  push(lines, "")
  for _, item in ipairs(bullets) do
    push(lines, "- " .. item)
  end
  if #bullets == 0 then
    push(lines, "- No guarded highlights survived the current translation and validation pass.")
  end
  push(lines, "")

  return table.concat(lines, "\n") .. "\n"
end

return M
