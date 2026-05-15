local parser = require("cli.parse")
local json = require("core.json")
local pipeline = require("core.pipeline")

local M = {}

local function usage()
  return table.concat({
    "usage:",
    "  lua main.lua scan --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua classify --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua truth --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua run --repos ./repo1 ./repo2 --out ./wolfcv-out",
  }, "\n")
end

function M.run(argv)
  local config = parser.parse(argv)

  if config.command == "help" then
    io.stdout:write(usage() .. "\n")
    return
  end

  if config.command == "scan" then
    local result = pipeline.run_scan(config)
    io.stdout:write(json.encode_pretty({
      command = "scan",
      repositories = #result.repositories,
      artifacts = #result.artifacts,
      out = config.out,
    }) .. "\n")
  elseif config.command == "classify" then
    local scan_result = pipeline.run_scan(config)
    local classified, runtime_cfg = pipeline.run_classify(config, scan_result)
    io.stdout:write(json.encode_pretty({
      command = "classify",
      repositories = #scan_result.repositories,
      artifacts = #scan_result.artifacts,
      classified_artifacts = #classified,
      provider = runtime_cfg.provider,
      model = runtime_cfg.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "truth" or config.command == "run" then
    local result = pipeline.run_truth(config)
    io.stdout:write(json.encode_pretty({
      command = config.command,
      repositories = #result.repositories,
      artifacts = #result.artifacts,
      classified_artifacts = #result.classified_artifacts,
      evidence = #result.evidence,
      claims = #result.claims,
      provider = result.runtime.provider,
      model = result.runtime.model,
      out = config.out,
    }) .. "\n")
  else
    error("unsupported command for first cut: " .. config.command)
  end
end

return M
