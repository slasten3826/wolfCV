local json = require("core.json")
local ids = require("core.ids")
local schema = require("schemas.guard_result_batch")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV guard stage.",
  "Task: judge whether translated draft usage stays within evidence-backed claim boundaries.",
  "Do not loosen scope. Do not invent missing support.",
  "Return only JSON array.",
  "Return exactly one object for each supplied batch claim and no extra claims.",
  "Each object must contain:",
  "guard_id, claim_id, status, reason, recommended_wording, blocking_evidence_ids, missing_evidence, review_required",
  "Allowed status: SUPPORTED, PARTIALLY_SUPPORTED, RITUAL_TRANSLATION, UNSUPPORTED, FORBIDDEN.",
  "recommended_wording must be the safest usable recruiter-facing wording for that one claim.",
  "If a wording outruns support, lower status and narrow the wording.",
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

local function normalize_items(items)
  if type(items) ~= "table" then
    return items
  end

  for index, item in ipairs(items) do
    if type(item) == "table" then
      local seed = item.claim_id or ("claim_" .. tostring(index))
      item.guard_id = item.guard_id or ids.guard_id(seed, index)
      item.blocking_evidence_ids = normalize_array(item.blocking_evidence_ids)
      item.missing_evidence = normalize_array(item.missing_evidence)
      item.reason = type(item.reason) == "string" and item.reason or "No reason provided."
      item.recommended_wording = type(item.recommended_wording) == "string" and item.recommended_wording ~= "" and item.recommended_wording or "Review wording manually."
      if type(item.review_required) ~= "boolean" then
        item.review_required = item.status == "UNSUPPORTED" or item.status == "FORBIDDEN"
      end
    end
  end

  return items
end

function M.stage()
  return {
    name = "guard",
    version = "v0",
    input_schema = "claim_batch_plus_evidence_and_draft",
    output_schema = "guard_result_batch",
    build_system_prompt = function()
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet)
      return table.concat({
        "Guard these translated claims against evidence-backed support.",
        "Return JSON array only.",
        input_packet.forbidden_claims and ("Forbidden claims:\n" .. input_packet.forbidden_claims) or "Forbidden claims: none",
        "Vacancy map:",
        json.encode_pretty(input_packet.vacancy_map),
        "Draft:",
        json.encode_pretty(input_packet.draft),
        "Claims for this batch:",
        json.encode_pretty(input_packet.claims),
        "Relevant evidence:",
        json.encode_pretty(input_packet.evidence),
      }, "\n\n")
    end,
    parse_output = function(text)
      local cleaned = text
      cleaned = cleaned:gsub("^```json%s*", "")
      cleaned = cleaned:gsub("^```%s*", "")
      cleaned = cleaned:gsub("%s*```%s*$", "")
      return normalize_items(json.decode(cleaned))
    end,
    validate_output = function(obj)
      return schema.validate(obj)
    end,
  }
end

return M
