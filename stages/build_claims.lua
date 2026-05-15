local json = require("core.json")
local schema = require("schemas.claim_batch")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV build_claims stage.",
  "Task: convert bounded evidence into recruiter-usable claims without falsification.",
  "Claims must stay traceable to supporting evidence.",
  "Do not invent employers, years, production deployments, team structures, or metrics.",
  "Return only JSON array.",
  "Each claim object must contain:",
  "claim_id, text, normalized_skill_tags, support_level, supporting_evidence_ids, risk_level, scope, safe_for_cv, safer_wording, forbidden_reason",
  "Allowed support_level: SUPPORTED, PARTIALLY_SUPPORTED, RITUAL_TRANSLATION, UNSUPPORTED, FORBIDDEN.",
  "Allowed risk_level: low, medium, high.",
  "Allowed scope: concept, prototype, runnable, production_like, production.",
  "If a claim is unsupported or too risky, mark safe_for_cv=false and provide forbidden_reason or a safer_wording.",
  "Prefer claims about architecture, specification, tooling, prototypes, and research when evidence supports them.",
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

  for _, item in ipairs(items) do
    item.normalized_skill_tags = normalize_array(item.normalized_skill_tags)
    item.supporting_evidence_ids = normalize_array(item.supporting_evidence_ids)
    if type(item.safe_for_cv) ~= "boolean" then
      item.safe_for_cv = item.support_level == "SUPPORTED" or item.support_level == "PARTIALLY_SUPPORTED"
    end
    if type(item.safer_wording) ~= "string" or item.safer_wording == "" then
      item.safer_wording = item.text or ""
    end
    if type(item.risk_level) ~= "string" or item.risk_level == "" then
      item.risk_level = "medium"
    end
    if type(item.scope) ~= "string" or item.scope == "" then
      item.scope = "prototype"
    end
    if type(item.support_level) ~= "string" or item.support_level == "" then
      item.support_level = "PARTIALLY_SUPPORTED"
    end
  end

  return items
end

function M.stage()
  return {
    name = "build_claims",
    version = "v0",
    input_schema = "evidence_batch",
    output_schema = "claim_batch",
    build_system_prompt = function()
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet)
      return table.concat({
        "Build guarded claims from this evidence.",
        "Return JSON array only.",
        input_packet.notes and ("Candidate notes:\n" .. input_packet.notes) or "Candidate notes: none",
        input_packet.forbidden_claims and ("Forbidden claims:\n" .. input_packet.forbidden_claims) or "Forbidden claims: none",
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
