local M = {}

local function require_string(item, key)
  return type(item[key]) == "string" and item[key] ~= ""
end

local function require_array(item, key)
  return type(item[key]) == "table"
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
  if type(item.ritualization_score) ~= "number" then
    return false, "vacancy map missing ritualization_score"
  end

  return true
end

return M
