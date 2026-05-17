local json = require("core.json")
local ids = require("core.ids")
local schema = require("schemas.vacancy_map")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV parse_vacancy stage.",
  "Task: normalize one job vacancy into machine-usable pressure and diagnose the real role shape behind the wording.",
  "Separate hard requirements from softer preference signals.",
  "Separate core task surface from ritual language and status decoration.",
  "Do not invent company facts beyond the provided vacancy text.",
  "Return only one JSON object.",
  "Object fields must be:",
  "vacancy_id, title, raw_text_path, keywords, hard_requirements, soft_requirements, domain_tags, seniority_signals, role_archetype, core_task_surface, stack_signals, likely_hidden_role, red_flags, ritualization_score, breadth_overload_score, domain_specificity_score, infra_weight, research_weight, social_coordination_weight",
  "Keep requirement text short and close to the source wording.",
  "Scores must be numbers between 0 and 1.",
  "role_archetype should be a short label like: ml_generalist, llm_systems, qa_automation, cv_specialist, architect_social_player, product_ml, ai_integrator.",
  "likely_hidden_role should be one short sentence describing what the company actually seems to need.",
  "red_flags should only include concrete risk patterns visible in the text.",
}, "\n")

local function normalize_array(value)
  if type(value) == "table" then
    return value
  end
  if type(value) == "string" and value ~= "" then
    return { value }
  end
  return {}
end

local function is_placeholder_string(value)
  if type(value) ~= "string" then
    return false
  end
  local normalized = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
  return normalized == ""
    or normalized == "unknown"
    or normalized == "n/a"
    or normalized == "na"
    or normalized == "none"
    or normalized == "null"
end

local function normalize_score(value, fallback)
  local number = tonumber(value) or fallback
  if number < 0 then
    return 0
  end
  if number > 1 then
    return 1
  end
  return number
end

local function normalize_item(item, input_packet)
  if type(item) ~= "table" then
    return item
  end

  item.title = (type(item.title) == "string" and not is_placeholder_string(item.title)) and item.title or "Untitled vacancy"
  item.raw_text_path = input_packet.raw_text_path
  item.vacancy_id = (type(item.vacancy_id) == "string" and not is_placeholder_string(item.vacancy_id)) and item.vacancy_id or ids.vacancy_id(item.title)
  item.keywords = normalize_array(item.keywords)
  item.hard_requirements = normalize_array(item.hard_requirements)
  item.soft_requirements = normalize_array(item.soft_requirements)
  item.domain_tags = normalize_array(item.domain_tags)
  item.seniority_signals = normalize_array(item.seniority_signals)
  item.role_archetype = (type(item.role_archetype) == "string" and not is_placeholder_string(item.role_archetype)) and item.role_archetype or "unknown"
  item.core_task_surface = normalize_array(item.core_task_surface)
  item.stack_signals = normalize_array(item.stack_signals)
  item.likely_hidden_role = (type(item.likely_hidden_role) == "string" and not is_placeholder_string(item.likely_hidden_role)) and item.likely_hidden_role or "Role shape unclear from vacancy text."
  item.red_flags = normalize_array(item.red_flags)
  item.ritualization_score = normalize_score(item.ritualization_score, 0.5)
  item.breadth_overload_score = normalize_score(item.breadth_overload_score, 0.5)
  item.domain_specificity_score = normalize_score(item.domain_specificity_score, 0.5)
  item.infra_weight = normalize_score(item.infra_weight, 0.5)
  item.research_weight = normalize_score(item.research_weight, 0.5)
  item.social_coordination_weight = normalize_score(item.social_coordination_weight, 0.5)

  return item
end

function M.stage()
  return {
    name = "parse_vacancy",
    version = "v0",
    input_schema = "vacancy_text",
    output_schema = "vacancy_map",
    build_system_prompt = function()
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet)
      return table.concat({
        "Normalize this vacancy into machine-usable pressure.",
        "Return one JSON object only.",
        "Preserve raw_text_path exactly.",
        "raw_text_path: " .. input_packet.raw_text_path,
        input_packet.notes and ("Candidate notes:\n" .. input_packet.notes) or "Candidate notes: none",
        input_packet.raw_text,
      }, "\n\n")
    end,
    parse_output = function(text)
      local cleaned = text
      cleaned = cleaned:gsub("^```json%s*", "")
      cleaned = cleaned:gsub("^```%s*", "")
      cleaned = cleaned:gsub("%s*```%s*$", "")
      return normalize_item(json.decode(cleaned), {
        raw_text_path = "__runtime__",
      })
    end,
    validate_output = function(obj)
      return schema.validate(obj)
    end,
  }
end

function M.normalize_output(obj, input_packet)
  return normalize_item(obj, input_packet)
end

return M
