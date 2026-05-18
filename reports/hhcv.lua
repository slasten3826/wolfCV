local M = {}

local ALLOWED_STATUS = {
  SUPPORTED = true,
  PARTIALLY_SUPPORTED = true,
  RITUAL_TRANSLATION = true,
}

local function push(lines, value)
  lines[#lines + 1] = value
end

local function unique_strings(items)
  local out = {}
  local seen = {}
  for _, item in ipairs(items or {}) do
    if type(item) == "string" and item ~= "" and not seen[item] then
      out[#out + 1] = item
      seen[item] = true
    end
  end
  return out
end

local function supported_bullets(draft, guard_results)
  local out = {}
  local guard_map = {}
  for _, item in ipairs(guard_results or {}) do
    guard_map[item.claim_id] = item
  end

  for _, bullet in ipairs((draft or {}).project_bullets or {}) do
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
  local skills = unique_strings(draft.skill_blocks)
  local bullets = supported_bullets(draft, guard_results)
  local title = draft.role_title or vacancy_map.title or "Желаемая должность"

  push(lines, "# HH CV Draft")
  push(lines, "")
  push(lines, "## Желаемая должность")
  push(lines, "")
  push(lines, title)
  push(lines, "")

  push(lines, "## Обо мне")
  push(lines, "")
  push(lines, draft.summary or "")
  push(lines, "")

  push(lines, "## Ключевые навыки")
  push(lines, "")
  if #skills > 0 then
    for _, item in ipairs(skills) do
      push(lines, "- " .. item)
    end
  else
    push(lines, "- Нет достаточно сильного skill-surface для текущего таргета.")
  end
  push(lines, "")

  push(lines, "## Проектный опыт")
  push(lines, "")
  if #bullets > 0 then
    for _, item in ipairs(bullets) do
      push(lines, "- " .. item)
    end
  else
    push(lines, "- Для текущего таргета не survived ни один безопасный bullet после guard-проверки.")
  end
  push(lines, "")

  push(lines, "## Дополнительная информация")
  push(lines, "")
  push(lines, "- Этот draft ориентирован на hh.ru-форму, но не симулирует опыт работы, если employment truth не подтверждён.")
  push(lines, "- Вместо искусственной трудовой истории используется подтверждённый проектный опыт из репозиториев.")
  push(lines, "- Для полного чтения результата см. `machinecv.md`, `wolfcv.md` и `evidence_guard_report.md`.")
  push(lines, "")

  return table.concat(lines, "\n") .. "\n"
end

return M
