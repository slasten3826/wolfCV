local M = {}

function M.deepseek_key()
  return os.getenv("DEEPSEEK_API_KEY") or os.getenv("DEEPSEEK_KEY")
end

function M.default_runtime()
  return {
    provider = "deepseek",
    model = os.getenv("WOLFCV_MODEL") or "deepseek-v4-flash",
    temperature = tonumber(os.getenv("WOLFCV_TEMPERATURE") or "0.1"),
    max_tokens = tonumber(os.getenv("WOLFCV_MAX_TOKENS") or "4000"),
  }
end

function M.pipeline_limits()
  return {
    classify_batch_size = tonumber(os.getenv("WOLFCV_CLASSIFY_BATCH_SIZE") or "8"),
    classify_prompt_chars = tonumber(os.getenv("WOLFCV_CLASSIFY_PROMPT_CHARS") or "9000"),
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
