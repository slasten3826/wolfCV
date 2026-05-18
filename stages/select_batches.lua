local json = require("core.json")
local schema = require("schemas.batch_selection")

local M = {}

local PROMPT_HEADER = table.concat({
  "You are WolfCV select_batches stage.",
  "Task: decide which planned repository batches deserve deep evidence extraction for this vacancy.",
  "You are selecting reading targets, not writing CV text.",
  "Prefer batches that are likely to support the vacancy's core task surface.",
  "Avoid redundant low-value or weakly related batches.",
  "Return only JSON array.",
  "Each item must contain: batch_id, decision, reason, target_surface, confidence.",
  "Allowed decision values: read_now, read_if_needed, skip.",
  "Use read_now for strongly relevant batches.",
  "Use read_if_needed for secondary batches that might fill gaps later.",
  "Use skip for low-value or irrelevant batches.",
}, "\n")

local function normalize_items(items)
  if type(items) ~= "table" then
    return items
  end
  for _, item in ipairs(items) do
    if type(item.confidence) ~= "number" then
      item.confidence = tonumber(item.confidence) or 0.5
    end
    if type(item.reason) ~= "string" or item.reason == "" then
      item.reason = tostring(item.reason or "No reason provided.")
    end
    if type(item.target_surface) ~= "string" or item.target_surface == "" then
      item.target_surface = "general"
    end
  end
  return items
end

function M.stage()
  return {
    name = "select_batches",
    version = "v0",
    input_schema = "vacancy_map_plus_batch_plan",
    output_schema = "batch_selection",
    response_format = { type = "json_object" },
    build_system_prompt = function()
      return PROMPT_HEADER
    end,
    build_user_prompt = function(input_packet)
      return table.concat({
        "Select planned batches for deep evidence extraction.",
        "Return JSON object with a single key named items containing the array.",
        "Vacancy map:",
        json.encode_pretty(input_packet.vacancy_map),
        "Planned batches:",
        json.encode_pretty(input_packet.batch_plan),
      }, "\n\n")
    end,
    parse_output = function(text)
      local cleaned = text
      cleaned = cleaned:gsub("^```json%s*", "")
      cleaned = cleaned:gsub("^```%s*", "")
      cleaned = cleaned:gsub("%s*```%s*$", "")
      local decoded = json.decode(cleaned)
      if type(decoded) == "table" and type(decoded.items) == "table" then
        return normalize_items(decoded.items)
      end
      return normalize_items(decoded)
    end,
    validate_output = function(obj)
      return schema.validate(obj)
    end,
  }
end

return M
