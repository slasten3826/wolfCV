local M = {}

local function push(lines, value)
  lines[#lines + 1] = value
end

local function push_list(lines, items)
  if not items or #items == 0 then
    push(lines, "- none")
    return
  end
  for _, item in ipairs(items) do
    push(lines, "- " .. tostring(item))
  end
end

local function fmt_score(value)
  local number = tonumber(value) or 0
  return string.format("%.2f", number)
end

function M.render(vacancy_map)
  local lines = {}
  push(lines, "# Vacancy Diagnosis")
  push(lines, "")
  push(lines, "Title: " .. tostring(vacancy_map.title or "Untitled vacancy"))
  push(lines, "Archetype: " .. tostring(vacancy_map.role_archetype or "unknown"))
  push(lines, "Likely hidden role: " .. tostring(vacancy_map.likely_hidden_role or "Role shape unclear"))
  push(lines, "")
  push(lines, "## Core Task Surface")
  push(lines, "")
  push_list(lines, vacancy_map.core_task_surface)
  push(lines, "")
  push(lines, "## Hard Requirements")
  push(lines, "")
  push_list(lines, vacancy_map.hard_requirements)
  push(lines, "")
  push(lines, "## Soft Requirements")
  push(lines, "")
  push_list(lines, vacancy_map.soft_requirements)
  push(lines, "")
  push(lines, "## Stack Signals")
  push(lines, "")
  push_list(lines, vacancy_map.stack_signals)
  push(lines, "")
  push(lines, "## Risk Signals")
  push(lines, "")
  push_list(lines, vacancy_map.red_flags)
  push(lines, "")
  push(lines, "## Pressure Scores")
  push(lines, "")
  push(lines, "- ritualization_score: " .. fmt_score(vacancy_map.ritualization_score))
  push(lines, "- breadth_overload_score: " .. fmt_score(vacancy_map.breadth_overload_score))
  push(lines, "- domain_specificity_score: " .. fmt_score(vacancy_map.domain_specificity_score))
  push(lines, "- infra_weight: " .. fmt_score(vacancy_map.infra_weight))
  push(lines, "- research_weight: " .. fmt_score(vacancy_map.research_weight))
  push(lines, "- social_coordination_weight: " .. fmt_score(vacancy_map.social_coordination_weight))
  push(lines, "")
  push(lines, "## Domain Tags")
  push(lines, "")
  push_list(lines, vacancy_map.domain_tags)
  push(lines, "")
  push(lines, "## Seniority Signals")
  push(lines, "")
  push_list(lines, vacancy_map.seniority_signals)
  push(lines, "")
  return table.concat(lines, "\n") .. "\n"
end

return M
