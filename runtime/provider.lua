local deepseek = require("runtime.deepseek")

local M = {}

function M.complete(runtime_cfg, request)
  if runtime_cfg.provider == "deepseek" then
    return deepseek.complete(runtime_cfg, request)
  end
  error("unsupported provider: " .. tostring(runtime_cfg.provider))
end

return M
