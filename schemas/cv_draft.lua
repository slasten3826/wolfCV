local M = {}

local function require_string(item, key)
  return type(item[key]) == "string" and item[key] ~= ""
end

function M.validate(item)
  if type(item) ~= "table" then
    return false, "cv draft must be a table"
  end
  if not require_string(item, "cvdraft_id") then
    return false, "cv draft missing cvdraft_id"
  end
  if not require_string(item, "vacancy_id") then
    return false, "cv draft missing vacancy_id"
  end
  if not require_string(item, "summary") then
    return false, "cv draft missing summary"
  end
  if not require_string(item, "role_title") then
    return false, "cv draft missing role_title"
  end
  if type(item.skill_blocks) ~= "table" then
    return false, "cv draft missing skill_blocks"
  end
  if type(item.project_bullets) ~= "table" then
    return false, "cv draft missing project_bullets"
  end
  if type(item.claim_ids) ~= "table" then
    return false, "cv draft missing claim_ids"
  end
  if not require_string(item, "target_mode") then
    return false, "cv draft missing target_mode"
  end

  for i = 1, #item.project_bullets do
    local bullet = item.project_bullets[i]
    if type(bullet) ~= "table" then
      return false, "project_bullet[" .. i .. "] must be a table"
    end
    if not require_string(bullet, "bullet_id") then
      return false, "project_bullet[" .. i .. "] missing bullet_id"
    end
    if not require_string(bullet, "text") then
      return false, "project_bullet[" .. i .. "] missing text"
    end
    if type(bullet.claim_ids) ~= "table" or #bullet.claim_ids == 0 then
      return false, "project_bullet[" .. i .. "] missing claim_ids"
    end
  end

  return true
end

return M
