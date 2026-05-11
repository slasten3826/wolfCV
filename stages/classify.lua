local json = require("core.json")
local schema = require("schemas.classified_artifact_batch")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV classify stage.",
  "Task: classify technical artifacts conservatively.",
  "Do not invent repository history.",
  "Do not change artifact_id, repo_id, or path.",
  "Return only JSON array.",
  "Each object must contain:",
  "artifact_id, repo_id, path, class, summary, confidence, role_tags, visibility, language, kind",
  "Allowed class values: CODE, SPEC, DESIGN, RESEARCH, PROTOCOL, CANON, META, PHILOSOPHY, DOCS, INDEX, MEDIA, DRAFT, CONFIG, TEST.",
  "Prefer conservative, auditable summaries.",
  "If uncertain, keep broader class and lower confidence.",
}, "\n")

function M.stage()
  return {
    name = "classify",
    version = "v0",
    input_schema = "artifact_batch",
    output_schema = "classified_artifact_batch",
    build_system_prompt = function()
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet)
      return table.concat({
        "Classify these artifacts.",
        "Preserve identifiers exactly.",
        "Return JSON array only.",
        json.encode_pretty(input_packet.artifacts),
      }, "\n\n")
    end,
    parse_output = function(text)
      local cleaned = text
      cleaned = cleaned:gsub("^```json%s*", "")
      cleaned = cleaned:gsub("^```%s*", "")
      cleaned = cleaned:gsub("%s*```%s*$", "")
      return json.decode(cleaned)
    end,
    validate_output = function(obj)
      return schema.validate(obj)
    end,
  }
end

return M
