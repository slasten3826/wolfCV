local config = require("core.config")
local fs = require("core.fs")
local json = require("core.json")

local M = {}

function M.complete(runtime_cfg, request)
  local key = config.deepseek_key()
  local provider_limits = config.provider_limits()
  if not key or key == "" then
    return {
      ok = false,
      provider = "deepseek",
      model = runtime_cfg.model,
      content = nil,
      raw = nil,
      error = "missing DEEPSEEK_API_KEY in environment",
    }
  end

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

  local request_path = os.tmpname()
  local response_path = os.tmpname()
  local stderr_path = os.tmpname()
  fs.write_file(request_path, json.encode_pretty(payload) .. "\n")

  local command = table.concat({
    "curl -sS https://api.deepseek.com/chat/completions",
    "--http1.1",
    "--retry " .. tostring(provider_limits.curl_retry_count),
    "--retry-all-errors",
    "--retry-delay " .. tostring(provider_limits.curl_retry_delay),
    "--connect-timeout " .. tostring(provider_limits.curl_connect_timeout),
    "--max-time " .. tostring(provider_limits.curl_max_time),
    "-H " .. fs.shell_quote("Content-Type: application/json"),
    "-H " .. fs.shell_quote("Authorization: Bearer " .. key),
    "--data-binary @" .. fs.shell_quote(request_path),
    "> " .. fs.shell_quote(response_path),
    "2> " .. fs.shell_quote(stderr_path),
  }, " ")

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
      provider = "deepseek",
      model = runtime_cfg.model,
      content = nil,
      raw = {
        body = body,
        stderr = stderr,
      },
      error = stderr ~= "" and ("deepseek request failed: " .. stderr:gsub("%s+$", "")) or "deepseek request failed",
    }
  end

  local decoded_ok, decoded = pcall(json.decode, body)
  if not decoded_ok then
    return {
      ok = false,
      provider = "deepseek",
      model = runtime_cfg.model,
      content = nil,
      raw = body,
      error = "failed to decode deepseek response: " .. tostring(decoded),
    }
  end

  local content = (((decoded or {}).choices or {})[1] or {}).message
  local finish_reason = (((decoded or {}).choices or {})[1] or {}).finish_reason
  if finish_reason == "length" then
    return {
      ok = false,
      provider = "deepseek",
      model = decoded.model or runtime_cfg.model,
      content = nil,
      raw = decoded,
      error = "deepseek response truncated: finish_reason=length",
    }
  end

  content = content and content.content or nil
  if type(content) ~= "string" or content == "" then
    return {
      ok = false,
      provider = "deepseek",
      model = runtime_cfg.model,
      content = nil,
      raw = decoded,
      error = "deepseek response missing choices[1].message.content",
    }
  end

  return {
    ok = true,
    provider = "deepseek",
    model = decoded.model or runtime_cfg.model,
    content = content,
    raw = decoded,
    error = nil,
  }
end

return M
