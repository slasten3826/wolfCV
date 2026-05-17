local config = require("core.config")
local fs = require("core.fs")
local json = require("core.json")

local M = {}

local function endpoint_for(runtime_cfg)
  local base_url = runtime_cfg.base_url or os.getenv("OPENAI_BASE_URL")
  if not base_url or base_url == "" then
    return nil
  end

  if base_url:match("/chat/completions/?$") then
    return base_url
  end

  return base_url:gsub("/+$", "") .. "/chat/completions"
end

function M.complete(runtime_cfg, request)
  local endpoint = endpoint_for(runtime_cfg)
  local provider_limits = config.provider_limits()

  if not endpoint then
    return {
      ok = false,
      provider = "openai_compat",
      model = runtime_cfg.model,
      content = nil,
      raw = nil,
      error = "missing OPENAI-compatible base URL",
    }
  end

  local key = runtime_cfg.api_key or config.openai_compat_key()
  local payload = {
    model = runtime_cfg.model,
    temperature = request.temperature or runtime_cfg.temperature or 0.1,
    max_tokens = request.max_tokens or runtime_cfg.max_tokens or 4000,
    messages = {
      {
        role = "system",
        content = request.system,
      },
      {
        role = "user",
        content = request.user,
      },
    },
  }

  if request.response_format then
    payload.response_format = request.response_format
  end

  local request_path = os.tmpname()
  local response_path = os.tmpname()
  local stderr_path = os.tmpname()
  fs.write_file(request_path, json.encode_pretty(payload) .. "\n")

  local parts = {
    "curl -sS " .. fs.shell_quote(endpoint),
    "--http1.1",
    "--retry " .. tostring(provider_limits.curl_retry_count),
    "--retry-all-errors",
    "--retry-delay " .. tostring(provider_limits.curl_retry_delay),
    "--connect-timeout " .. tostring(provider_limits.curl_connect_timeout),
    "--max-time " .. tostring(provider_limits.curl_max_time),
    "-H " .. fs.shell_quote("Content-Type: application/json"),
  }

  if key and key ~= "" then
    parts[#parts + 1] = "-H " .. fs.shell_quote("Authorization: Bearer " .. key)
  end

  parts[#parts + 1] = "--data-binary @" .. fs.shell_quote(request_path)
  parts[#parts + 1] = "> " .. fs.shell_quote(response_path)
  parts[#parts + 1] = "2> " .. fs.shell_quote(stderr_path)

  local command = table.concat(parts, " ")
  local ok = os.execute(command)
  local body = ""
  local stderr = ""
  if fs.exists(response_path) then
    body = fs.read_file(response_path)
  end
  if fs.exists(stderr_path) then
    stderr = fs.read_file(stderr_path)
  end

  os.remove(request_path)
  os.remove(response_path)
  os.remove(stderr_path)

  if not (ok == true or ok == 0) then
    return {
      ok = false,
      provider = "openai_compat",
      model = runtime_cfg.model,
      content = nil,
      raw = {
        body = body,
        stderr = stderr,
      },
      error = stderr ~= "" and ("openai-compatible request failed: " .. stderr:gsub("%s+$", "")) or "openai-compatible request failed",
    }
  end

  local decoded_ok, decoded = pcall(json.decode, body)
  if not decoded_ok then
    return {
      ok = false,
      provider = "openai_compat",
      model = runtime_cfg.model,
      content = nil,
      raw = body,
      error = "failed to decode openai-compatible response: " .. tostring(decoded),
    }
  end

  local choice = (((decoded or {}).choices or {})[1] or {})
  local content = (choice.message or {}).content
  local finish_reason = choice.finish_reason
  if finish_reason == "length" then
    return {
      ok = false,
      provider = "openai_compat",
      model = decoded.model or runtime_cfg.model,
      content = nil,
      raw = decoded,
      error = "openai-compatible response truncated: finish_reason=length",
    }
  end

  if type(content) ~= "string" or content == "" then
    return {
      ok = false,
      provider = "openai_compat",
      model = decoded.model or runtime_cfg.model,
      content = nil,
      raw = decoded,
      error = "openai-compatible response missing choices[1].message.content",
    }
  end

  return {
    ok = true,
    provider = "openai_compat",
    model = decoded.model or runtime_cfg.model,
    content = content,
    raw = decoded,
    error = nil,
  }
end

return M
