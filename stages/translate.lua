local json = require("core.json")
local ids = require("core.ids")
local schema = require("schemas.cv_draft")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV translate stage.",
  "Task: build a vacancy-facing CV draft from already supported claims.",
  "Do not invent employers, dates, deployments, team size, metrics, degrees, or production scope.",
  "Use only the supplied claims and vacancy pressure.",
  "Return only one JSON object.",
  "Object fields must be:",
  "cvdraft_id, vacancy_id, summary, role_title, skill_blocks, project_bullets, claim_ids, target_mode",
  "Each project_bullet must contain: bullet_id, text, claim_ids.",
  "Use at most one claim id per bullet for easier guarding.",
  "Select only the safest and most vacancy-relevant claims.",
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

local function normalize_skill_blocks(value)
  if type(value) ~= "table" then
    return {}
  end

  local out = {}
  for _, item in ipairs(value) do
    if type(item) == "string" and item ~= "" then
      out[#out + 1] = item
    elseif type(item) == "table" then
      if type(item.block_title) == "string" and item.block_title ~= "" then
        out[#out + 1] = item.block_title
      elseif type(item.title) == "string" and item.title ~= "" then
        out[#out + 1] = item.title
      end
    end
  end
  return out
end

local function normalize_bullets(value)
  if type(value) ~= "table" then
    return {}
  end

  local out = {}
  for index, item in ipairs(value) do
    if type(item) == "string" and item ~= "" then
      out[#out + 1] = {
        bullet_id = "bullet_" .. tostring(index),
        text = item,
        claim_ids = {},
      }
    elseif type(item) == "table" then
      out[#out + 1] = {
        bullet_id = (type(item.bullet_id) == "string" and item.bullet_id ~= "") and item.bullet_id or ("bullet_" .. tostring(index)),
        text = type(item.text) == "string" and item.text or "",
        claim_ids = normalize_array(item.claim_ids),
      }
    end
  end
  return out
end

local function normalize_item(item, input_packet)
  if type(item) ~= "table" then
    return item
  end

  local vacancy_id = (((input_packet or {}).vacancy_map or {}).vacancy_id) or "vacancy"
  item.vacancy_id = type(item.vacancy_id) == "string" and item.vacancy_id ~= "" and item.vacancy_id or vacancy_id
  item.cvdraft_id = item.cvdraft_id or ids.cvdraft_id(item.vacancy_id)
  item.summary = type(item.summary) == "string" and item.summary or "Evidence-backed draft."
  item.role_title = type(item.role_title) == "string" and item.role_title or (((input_packet or {}).vacancy_map or {}).title) or "Target role"
  item.skill_blocks = normalize_skill_blocks(item.skill_blocks)
  item.project_bullets = normalize_bullets(item.project_bullets)
  item.claim_ids = normalize_array(item.claim_ids)
  item.target_mode = type(item.target_mode) == "string" and item.target_mode or "wolfcv"
  return item
end

function M.stage()
  return {
    name = "translate",
    version = "v0",
    input_schema = "claim_batch_plus_vacancy",
    output_schema = "cv_draft",
    build_system_prompt = function()
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet)
      return table.concat({
        "Build a guarded vacancy-facing CV draft.",
        "Return one JSON object only.",
        input_packet.notes and ("Candidate notes:\n" .. input_packet.notes) or "Candidate notes: none",
        "Vacancy map:",
        json.encode_pretty(input_packet.vacancy_map),
        "Safe claims:",
        json.encode_pretty(input_packet.claims),
      }, "\n\n")
    end,
    parse_output = function(text)
      local cleaned = text
      cleaned = cleaned:gsub("^```json%s*", "")
      cleaned = cleaned:gsub("^```%s*", "")
      cleaned = cleaned:gsub("%s*```%s*$", "")
      return normalize_item(json.decode(cleaned), nil)
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
