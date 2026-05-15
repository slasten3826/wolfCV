local json = require("core.json")
local ids = require("core.ids")
local schema = require("schemas.vacancy_map")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV parse_vacancy stage.",
  "Task: normalize one job vacancy into machine-usable pressure.",
  "Separate hard requirements from softer preference signals.",
  "Do not invent company facts beyond the provided vacancy text.",
  "Return only one JSON object.",
  "Object fields must be:",
  "vacancy_id, title, raw_text_path, keywords, hard_requirements, soft_requirements, domain_tags, seniority_signals, ritualization_score",
  "Keep requirement text short and close to the source wording.",
  "ritualization_score must be a number between 0 and 1.",
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

local function normalize_item(item, input_packet)
  if type(item) ~= "table" then
    return item
  end

  item.title = (type(item.title) == "string" and item.title ~= "") and item.title or "Untitled vacancy"
  item.raw_text_path = input_packet.raw_text_path
  item.vacancy_id = (type(item.vacancy_id) == "string" and item.vacancy_id ~= "") and item.vacancy_id or ids.vacancy_id(item.title)
  item.keywords = normalize_array(item.keywords)
  item.hard_requirements = normalize_array(item.hard_requirements)
  item.soft_requirements = normalize_array(item.soft_requirements)
  item.domain_tags = normalize_array(item.domain_tags)
  item.seniority_signals = normalize_array(item.seniority_signals)
  item.ritualization_score = tonumber(item.ritualization_score) or 0.5

  if item.ritualization_score < 0 then
    item.ritualization_score = 0
  elseif item.ritualization_score > 1 then
    item.ritualization_score = 1
  end

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
