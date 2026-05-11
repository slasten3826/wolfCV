local fs = require("core.fs")
local json = require("core.json")
local provider = require("runtime.provider")

local M = {}

local function write_trace_file(trace_dir, name, value)
  if type(value) == "table" then
    fs.write_file(fs.join(trace_dir, name), json.encode_pretty(value) .. "\n")
  else
    fs.write_file(fs.join(trace_dir, name), tostring(value or "") .. "\n")
  end
end

function M.run(stage, input_packet, runtime_cfg, out_dir)
  local trace_dir = fs.join(out_dir, "traces", stage.name)
  fs.mkdir_p(trace_dir)
  write_trace_file(trace_dir, "input.json", input_packet)

  local system_prompt = assert(stage.build_system_prompt(input_packet))
  local user_prompt = assert(stage.build_user_prompt(input_packet))
  write_trace_file(trace_dir, "system_prompt.txt", system_prompt)
  write_trace_file(trace_dir, "user_prompt.txt", user_prompt)

  local response = provider.complete(runtime_cfg, {
    system = system_prompt,
    user = user_prompt,
    temperature = runtime_cfg.temperature,
    max_tokens = runtime_cfg.max_tokens,
  })

  write_trace_file(trace_dir, "provider_response.json", response)
  if not response.ok then
    return nil, response.error
  end

  local parsed = stage.parse_output(response.content)
  write_trace_file(trace_dir, "parsed_output.json", parsed)

  local ok, err = stage.validate_output(parsed)
  write_trace_file(trace_dir, "validation.json", { ok = ok, error = err })
  if not ok then
    return nil, err
  end

  return parsed
end

return M
