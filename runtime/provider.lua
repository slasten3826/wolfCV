local deepseek = require("runtime.deepseek")
local openai_compat = require("runtime.openai_compat")

local M = {}

function M.complete(runtime_cfg, request)
  if runtime_cfg.provider == "deepseek" then
    return deepseek.complete(runtime_cfg, request)
  end
  if runtime_cfg.provider == "openai_compat" then
    return openai_compat.complete(runtime_cfg, request)
  end
  error("unsupported provider: " .. tostring(runtime_cfg.provider))
end

return M
