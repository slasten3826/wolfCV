local M = {}

function M.deepseek_key()
  return os.getenv("DEEPSEEK_API_KEY") or os.getenv("DEEPSEEK_KEY")
end

local function normalize_stage_key(stage_name)
  if type(stage_name) ~= "string" or stage_name == "" then
    return nil
  end

  local trimmed = stage_name:gsub("_batch_.*$", "")
  trimmed = trimmed:gsub("[^%w]+", "_")
  trimmed = trimmed:upper()
  return trimmed
end

local function runtime_env(stage_name, suffix, fallback)
  local stage_key = normalize_stage_key(stage_name)
  if stage_key then
    local stage_value = os.getenv("WOLFCV_" .. stage_key .. "_" .. suffix)
    if stage_value ~= nil and stage_value ~= "" then
      return stage_value
    end
  end

  local global_value = os.getenv("WOLFCV_" .. suffix)
  if global_value ~= nil and global_value ~= "" then
    return global_value
  end

  return fallback
end

function M.openai_compat_key(stage_name)
  return runtime_env(stage_name, "API_KEY", os.getenv("OPENAI_API_KEY"))
end

function M.default_runtime(stage_name)
  return {
    provider = runtime_env(stage_name, "PROVIDER", "deepseek"),
    model = runtime_env(stage_name, "MODEL", "deepseek-v4-flash"),
    base_url = runtime_env(stage_name, "BASE_URL", os.getenv("OPENAI_BASE_URL")),
    api_key = runtime_env(stage_name, "API_KEY", nil),
    temperature = tonumber(runtime_env(stage_name, "TEMPERATURE", "0.1")),
    max_tokens = tonumber(runtime_env(stage_name, "MAX_TOKENS", "4000")),
  }
end

function M.pipeline_limits()
  return {
    classify_batch_size = tonumber(os.getenv("WOLFCV_CLASSIFY_BATCH_SIZE") or "8"),
    classify_prompt_chars = tonumber(os.getenv("WOLFCV_CLASSIFY_PROMPT_CHARS") or "9000"),
    planning_batch_size = tonumber(os.getenv("WOLFCV_PLANNING_BATCH_SIZE") or "8"),
    planning_prompt_chars = tonumber(os.getenv("WOLFCV_PLANNING_PROMPT_CHARS") or "12000"),
    evidence_batch_size = tonumber(os.getenv("WOLFCV_EVIDENCE_BATCH_SIZE") or "2"),
    claim_batch_size = tonumber(os.getenv("WOLFCV_CLAIM_BATCH_SIZE") or "10"),
    guard_batch_size = tonumber(os.getenv("WOLFCV_GUARD_BATCH_SIZE") or "8"),
    source_excerpt_chars = tonumber(os.getenv("WOLFCV_SOURCE_EXCERPT_CHARS") or "2500"),
    evidence_prompt_chars = tonumber(os.getenv("WOLFCV_EVIDENCE_PROMPT_CHARS") or "9000"),
  }
end

function M.provider_limits()
  return {
    curl_retry_count = tonumber(os.getenv("WOLFCV_CURL_RETRY_COUNT") or "3"),
    curl_retry_delay = tonumber(os.getenv("WOLFCV_CURL_RETRY_DELAY") or "2"),
    curl_connect_timeout = tonumber(os.getenv("WOLFCV_CURL_CONNECT_TIMEOUT") or "20"),
    curl_max_time = tonumber(os.getenv("WOLFCV_CURL_MAX_TIME") or "180"),
  }
end

return M
