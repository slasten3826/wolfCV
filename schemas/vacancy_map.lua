local M = {}

local function require_string(item, key)
  return type(item[key]) == "string" and item[key] ~= ""
end

local function require_array(item, key)
  return type(item[key]) == "table"
end

local function require_number(item, key)
  return type(item[key]) == "number"
end

function M.validate(item)
  if type(item) ~= "table" then
    return false, "vacancy map must be a table"
  end
  if not require_string(item, "vacancy_id") then
    return false, "vacancy map missing vacancy_id"
  end
  if not require_string(item, "title") then
    return false, "vacancy map missing title"
  end
  if not require_string(item, "raw_text_path") then
    return false, "vacancy map missing raw_text_path"
  end
  if not require_array(item, "keywords") then
    return false, "vacancy map missing keywords"
  end
  if not require_array(item, "hard_requirements") then
    return false, "vacancy map missing hard_requirements"
  end
  if not require_array(item, "soft_requirements") then
    return false, "vacancy map missing soft_requirements"
  end
  if not require_array(item, "domain_tags") then
    return false, "vacancy map missing domain_tags"
  end
  if not require_array(item, "seniority_signals") then
    return false, "vacancy map missing seniority_signals"
  end
  if not require_string(item, "role_archetype") then
    return false, "vacancy map missing role_archetype"
  end
  if not require_array(item, "core_task_surface") then
    return false, "vacancy map missing core_task_surface"
  end
  if not require_array(item, "stack_signals") then
    return false, "vacancy map missing stack_signals"
  end
  if not require_string(item, "likely_hidden_role") then
    return false, "vacancy map missing likely_hidden_role"
  end
  if not require_array(item, "red_flags") then
    return false, "vacancy map missing red_flags"
  end
  if not require_number(item, "ritualization_score") then
    return false, "vacancy map missing ritualization_score"
  end
  if not require_number(item, "breadth_overload_score") then
    return false, "vacancy map missing breadth_overload_score"
  end
  if not require_number(item, "domain_specificity_score") then
    return false, "vacancy map missing domain_specificity_score"
  end
  if not require_number(item, "infra_weight") then
    return false, "vacancy map missing infra_weight"
  end
  if not require_number(item, "research_weight") then
    return false, "vacancy map missing research_weight"
  end
  if not require_number(item, "social_coordination_weight") then
    return false, "vacancy map missing social_coordination_weight"
  end

  return true
end

return M
