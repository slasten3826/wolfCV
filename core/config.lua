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

return M
