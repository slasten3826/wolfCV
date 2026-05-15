local json = require("core.json")
local schema = require("schemas.evidence_batch")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV extract_evidence stage.",
  "Task: convert classified technical artifacts into bounded evidence statements.",
  "Evidence must stay local, factual, and smaller than a CV claim.",
  "Do not invent deployment, team size, employer history, dates, users, metrics, or production usage.",
  "Return at most one evidence object per artifact.",
  "Prefer the single strongest local evidence statement for each artifact.",
  "Return only JSON array.",
  "Each evidence object must contain:",
  "evidence_id, statement, source_artifacts, source_spans, evidence_type, strength, scope, supports_skills, limitations, confidence",
  "Allowed strength: weak, medium, strong.",
  "Allowed scope: concept, prototype, runnable, production_like, production.",
  "Allowed evidence_type: CODE, SPEC, DESIGN, RESEARCH, PROTOCOL, CANON, DOCS, TEST.",
  "Use source excerpts only as bounded local support.",
  "When uncertain, lower strength and narrow scope.",
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

local function normalize_source_spans(value)
  if type(value) == "string" then
    return value ~= "" and value or "excerpt"
  end
  if type(value) == "table" then
    local parts = {}
    for _, item in ipairs(value) do
      parts[#parts + 1] = tostring(item)
    end
    local joined = table.concat(parts, ", ")
    return joined ~= "" and joined or "excerpt"
  end
  return "excerpt"
end

local function normalize_items(items)
  if type(items) ~= "table" then
    return items
  end

  for _, item in ipairs(items) do
    if (type(item.statement) ~= "string" or item.statement == "") and type(item.evidence) == "string" then
      item.statement = item.evidence
    end
    item.source_artifacts = normalize_array(item.source_artifacts)
    item.supports_skills = normalize_array(item.supports_skills)
    item.limitations = normalize_array(item.limitations)
    item.source_spans = normalize_source_spans(item.source_spans)
    if type(item.confidence) ~= "number" then
      item.confidence = tonumber(item.confidence) or 0.5
    end
  end

  return items
end

function M.stage()
  return {
    name = "extract_evidence",
    version = "v0",
    input_schema = "classified_artifact_batch_with_excerpts",
    output_schema = "evidence_batch",
    build_system_prompt = function()
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet)
      return table.concat({
        "Extract bounded evidence from these artifacts.",
        "Produce no more than one evidence object per artifact.",
        "Preserve source linkage.",
        "Return JSON array only.",
        json.encode_pretty(input_packet.artifacts),
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
