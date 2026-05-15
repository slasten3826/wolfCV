local M = {}

local function push(lines, value)
  lines[#lines + 1] = value
end

function M.render(vacancy_map, draft)
  local lines = {}
  push(lines, "# WolfCV Draft")
  push(lines, "")
  push(lines, "Target: " .. (draft.role_title or vacancy_map.title or "Target role"))
  push(lines, "")
  push(lines, "## Summary")
  push(lines, "")
  push(lines, draft.summary or "")
  push(lines, "")
  push(lines, "## Skills")
  push(lines, "")
  for _, item in ipairs(draft.skill_blocks or {}) do
    push(lines, "- " .. tostring(item))
  end
  push(lines, "")
  push(lines, "## Project Bullets")
  push(lines, "")
  for _, bullet in ipairs(draft.project_bullets or {}) do
    push(lines, "- " .. bullet.text)
    push(lines, "  claim_ids: " .. table.concat(bullet.claim_ids or {}, ", "))
  end
  push(lines, "")
  return table.concat(lines, "\n") .. "\n"
end

return M
