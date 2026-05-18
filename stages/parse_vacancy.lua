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

local INTERESTING_HEADINGS = {
  "обязанности",
  "задачи",
  "что предстоит",
  "чем предстоит заниматься",
  "требования",
  "что ждем",
  "мы ждем",
  "ключевые требования",
  "must have",
  "requirements",
  "nice to have",
  "будет плюсом",
  "стек",
  "our stack",
  "stack",
}

local INTERESTING_INLINE = {
  "rag",
  "llm",
  "agent",
  "prompt",
  "fastapi",
  "python",
  "docker",
  "kubernetes",
  "grafana",
  "mlflow",
  "cv",
  "nlp",
  "ocr",
  "embedding",
  "retrieval",
  "asyncio",
  "sql",
}

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function contains_any(text, needles)
  local lowered = text:lower()
  for _, needle in ipairs(needles) do
    if lowered:find(needle, 1, true) then
      return true
    end
  end
  return false
end

local function is_bullet_line(line)
  return line:match("^[-•*]") ~= nil or line:match("^%d+[.)]") ~= nil
end

local function compact_vacancy_text(raw_text)
  local kept = {}
  local section_hot = 0
  local total_chars = 0
  local first_nonempty_seen = 0

  for raw_line in raw_text:gmatch("[^\r\n]+") do
    local line = trim(raw_line)
    if line ~= "" then
      local lowered = line:lower()
      local keep = false

      if first_nonempty_seen < 3 then
        keep = true
        first_nonempty_seen = first_nonempty_seen + 1
      elseif contains_any(lowered, INTERESTING_HEADINGS) then
        keep = true
        section_hot = 6
      elseif section_hot > 0 and (is_bullet_line(line) or #line < 180) then
        keep = true
        section_hot = section_hot - 1
      elseif contains_any(lowered, INTERESTING_INLINE) and #line < 220 then
        keep = true
      end

      if keep then
        if total_chars + #line > 5000 or #kept >= 80 then
          break
        end
        kept[#kept + 1] = line
        total_chars = total_chars + #line
      end
    end
  end

  if #kept == 0 then
    local fallback = trim(raw_text)
    if #fallback > 5000 then
      fallback = fallback:sub(1, 5000)
    end
    return fallback
  end

  return table.concat(kept, "\n")
end

local function is_pro_runtime(runtime_cfg)
  local model = trim(runtime_cfg and runtime_cfg.model or ""):lower()
  return model:find("pro", 1, true) ~= nil
end

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

local function require_raw_string(item, key)
  return type(item[key]) == "string" and not is_placeholder_string(item[key])
end

local function require_raw_array(item, key)
  return type(item[key]) == "table"
end

local function require_raw_number(item, key)
  return type(item[key]) == "number"
end

local function validate_raw_contract(item)
  if type(item) ~= "table" then
    return false, "vacancy parse output must be a table"
  end

  local required_strings = {
    "title",
    "role_archetype",
    "likely_hidden_role",
  }
  for _, key in ipairs(required_strings) do
    if not require_raw_string(item, key) then
      return false, "vacancy parse output missing " .. key
    end
  end

  local required_arrays = {
    "hard_requirements",
    "soft_requirements",
    "stack_signals",
    "red_flags",
  }
  for _, key in ipairs(required_arrays) do
    if not require_raw_array(item, key) then
      return false, "vacancy parse output missing " .. key
    end
  end

  local required_numbers = {
    "ritualization_score",
    "breadth_overload_score",
    "domain_specificity_score",
    "infra_weight",
    "research_weight",
    "social_coordination_weight",
  }
  for _, key in ipairs(required_numbers) do
    if not require_raw_number(item, key) then
      return false, "vacancy parse output missing " .. key
    end
  end

  return true
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

local function assess_quality(item)
  local warnings = {}

  if item.title == "Untitled vacancy" then
    warnings[#warnings + 1] = "title missing or too weak in model output"
  end
  if item.role_archetype == "unknown" then
    warnings[#warnings + 1] = "role archetype unresolved"
  end
  if #item.core_task_surface == 0 then
    warnings[#warnings + 1] = "core task surface missing"
  end
  if #item.hard_requirements == 0 then
    warnings[#warnings + 1] = "hard requirements missing"
  end
  if #item.stack_signals == 0 then
    warnings[#warnings + 1] = "stack signals missing"
  end
  if item.likely_hidden_role == "Role shape unclear from vacancy text." then
    warnings[#warnings + 1] = "hidden role diagnosis missing"
  end

  local neutral_scores = 0
  local scores = {
    item.ritualization_score,
    item.breadth_overload_score,
    item.domain_specificity_score,
    item.infra_weight,
    item.research_weight,
    item.social_coordination_weight,
  }
  for _, value in ipairs(scores) do
    if tonumber(value) == 0.5 then
      neutral_scores = neutral_scores + 1
    end
  end
  if neutral_scores >= 4 then
    warnings[#warnings + 1] = "too many fallback-neutral scores"
  end

  local missing_core_count = 0
  if #item.core_task_surface == 0 then
    missing_core_count = missing_core_count + 1
  end
  if #item.hard_requirements == 0 then
    missing_core_count = missing_core_count + 1
  end
  if #item.stack_signals == 0 then
    missing_core_count = missing_core_count + 1
  end

  local quality = "solid"
  if item.title == "Untitled vacancy"
    or (item.role_archetype == "unknown" and item.likely_hidden_role == "Role shape unclear from vacancy text.")
    or missing_core_count >= 2
  then
    quality = "degraded"
  elseif #warnings > 0 then
    quality = "partial"
  end

  item.diagnosis_quality = quality
  item.contract_warnings = warnings
  return item
end

local function derive_archetype(item)
  local title = (item.title or ""):lower()
  local hidden = (item.likely_hidden_role or ""):lower()
  local joined_hard = table.concat(item.hard_requirements or {}, " "):lower()
  local joined_core = table.concat(item.core_task_surface or {}, " "):lower()
  local joined_stack = table.concat(item.stack_signals or {}, " "):lower()
  local joined_soft = table.concat(item.soft_requirements or {}, " "):lower()

  if (
    title:find("architect", 1, true)
    or title:find("архитектор", 1, true)
    or hidden:find("architect", 1, true)
    or hidden:find("архитектор", 1, true)
    or joined_core:find("stakeholder", 1, true)
    or joined_core:find("стейкхолдер", 1, true)
    or joined_core:find("standard", 1, true)
    or joined_core:find("координац", 1, true)
    or joined_core:find("унифиц", 1, true)
    or joined_hard:find("technical leadership", 1, true)
    or joined_hard:find("работы архитектором", 1, true)
  ) and item.social_coordination_weight >= 0.68 then
    return "architect_social_player"
  end

  if (
    joined_core:find("search", 1, true)
    or joined_hard:find("search", 1, true)
    or joined_stack:find("embedding", 1, true)
    or joined_stack:find("retrieval", 1, true)
  ) and (
    joined_hard:find("rag", 1, true)
    or joined_hard:find("llm", 1, true)
    or joined_core:find("llm", 1, true)
  ) then
    return "search_llm_hybrid"
  end

  local has_llm = joined_hard:find("llm", 1, true)
    or joined_hard:find("rag", 1, true)
    or joined_hard:find("трансформер", 1, true)
    or joined_stack:find("llm", 1, true)
    or joined_stack:find("gpt", 1, true)
    or joined_stack:find("bert", 1, true)
  local has_classic_ml = joined_hard:find("classical ml", 1, true)
    or joined_hard:find("eda", 1, true)
    or joined_hard:find("предобработ", 1, true)
    or joined_hard:find("preprocessing", 1, true)
    or joined_soft:find("modern approaches", 1, true)
  local has_ops_surface = joined_hard:find("ci/cd", 1, true)
    or joined_hard:find("jenkins", 1, true)
    or joined_hard:find("kubernetes", 1, true)
    or joined_stack:find("docker", 1, true)
    or joined_stack:find("prometheus", 1, true)
    or joined_stack:find("grafana", 1, true)
  local has_low_experience = joined_hard:find("1%+ year", 1)
    or joined_hard:find("1 year", 1, true)
    or joined_hard:find("от 1 года", 1, true)
    or table.concat(item.seniority_signals or {}, " "):lower():find("1%+ year", 1)
    or table.concat(item.seniority_signals or {}, " "):lower():find("junior", 1, true)

  if item.breadth_overload_score >= 0.78 and has_llm and has_classic_ml and has_ops_surface and has_low_experience then
    return "generic_ai_wishlist"
  end

  if item.breadth_overload_score >= 0.82 and item.domain_specificity_score <= 0.45 then
    return "generic_ai_wishlist"
  end

  return item.role_archetype
end

local function append_red_flag(flags, flag)
  for _, existing in ipairs(flags) do
    if existing == flag then
      return
    end
  end
  flags[#flags + 1] = flag
end

local function post_normalize(item)
  item.role_archetype = derive_archetype(item)

  if item.role_archetype == "architect_social_player" then
    append_red_flag(item.red_flags, "high coordination load disguised as technical role")
  end
  if item.role_archetype == "generic_ai_wishlist" then
    append_red_flag(item.red_flags, "role shape unclear; likely wishlist dump")
  end
  if item.breadth_overload_score >= 0.8 then
    append_red_flag(item.red_flags, "one person expected to cover too many adjacent functions")
  end

  return assess_quality(item)
end

function M.stage()
  return {
    name = "parse_vacancy",
    version = "v0",
    input_schema = "vacancy_text",
    output_schema = "vacancy_map",
    response_format = { type = "json_object" },
    build_system_prompt = function(_, runtime_cfg)
      if is_pro_runtime(runtime_cfg) then
        return table.concat({
          "You are WolfCV parse_vacancy stage.",
          "Read one job vacancy and return one compact JSON diagnosis object.",
          "Do not explain reasoning.",
          "Do not repeat marketing text.",
          "Separate real work surface from ritual language.",
          "Keep arrays short and high-signal.",
          "Scores must be numbers between 0 and 1.",
          "Return JSON only.",
        }, "\n")
      end
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet, runtime_cfg)
      local raw_text = input_packet.raw_text
      local required_keys_line = nil
      if is_pro_runtime(runtime_cfg) then
        raw_text = compact_vacancy_text(raw_text)
        required_keys_line = "Required JSON keys: title, hard_requirements, soft_requirements, role_archetype, core_task_surface, stack_signals, likely_hidden_role, red_flags, ritualization_score, breadth_overload_score, domain_specificity_score, infra_weight, research_weight, social_coordination_weight"
      end
      local parts = {
        "Normalize this vacancy into machine-usable pressure.",
        "Return one JSON object only.",
        "Preserve raw_text_path exactly.",
        "raw_text_path: " .. input_packet.raw_text_path,
        input_packet.notes and ("Candidate notes:\n" .. input_packet.notes) or "Candidate notes: none",
      }
      if required_keys_line then
        parts[#parts + 1] = required_keys_line
      end
      parts[#parts + 1] = raw_text
      return table.concat(parts, "\n\n")
    end,
    parse_output = function(text)
      local cleaned = text
      cleaned = cleaned:gsub("^```json%s*", "")
      cleaned = cleaned:gsub("^```%s*", "")
      cleaned = cleaned:gsub("%s*```%s*$", "")
      return json.decode(cleaned)
    end,
    validate_output = function(obj)
      return validate_raw_contract(obj)
    end,
  }
end

function M.normalize_output(obj, input_packet)
  return post_normalize(normalize_item(obj, input_packet))
end

return M
