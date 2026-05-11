local parser = require("cli.parse")
local fs = require("core.fs")
local json = require("core.json")
local config_mod = require("core.config")
local reports = require("reports.write")
local classify = require("stages.classify")
local scan = require("stages.scan")
local stage_runner = require("runtime.stage_runner")

local M = {}

local function usage()
  return table.concat({
    "usage:",
    "  lua main.lua scan --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua run  --repos ./repo1 ./repo2 --out ./wolfcv-out",
  }, "\n")
end

local function run_scan(config)
  if #config.repos == 0 then
    error("scan requires at least one repo via --repos")
  end

  local result = scan.run(config)
  reports.write_json(fs.join(config.out, "repository_index.json"), result.repositories)
  reports.write_json(fs.join(config.out, "artifacts.json"), result.artifacts)
  reports.write_text(fs.join(config.out, "scan_summary.txt"), scan.build_summary(result))

  io.stdout:write(json.encode_pretty({
    command = "scan",
    repositories = #result.repositories,
    artifacts = #result.artifacts,
    out = fs.abspath(config.out),
  }) .. "\n")
end

local function run_classify(config)
  if #config.repos == 0 then
    error("classify requires at least one repo via --repos")
  end

  local scan_result = scan.run(config)
  local runtime_cfg = config_mod.default_runtime()
  local stage = classify.stage()
  local classified, err = stage_runner.run(stage, {
    artifacts = scan_result.artifacts,
  }, runtime_cfg, config.out)

  if not classified then
    error(err)
  end

  reports.write_json(fs.join(config.out, "repository_index.json"), scan_result.repositories)
  reports.write_json(fs.join(config.out, "artifacts.json"), scan_result.artifacts)
  reports.write_json(fs.join(config.out, "classified_artifacts.json"), classified)

  io.stdout:write(json.encode_pretty({
    command = "classify",
    repositories = #scan_result.repositories,
    artifacts = #scan_result.artifacts,
    classified_artifacts = #classified,
    provider = runtime_cfg.provider,
    model = runtime_cfg.model,
    out = fs.abspath(config.out),
  }) .. "\n")
end

function M.run(argv)
  local config = parser.parse(argv)

  if config.command == "help" then
    io.stdout:write(usage() .. "\n")
    return
  end

  fs.mkdir_p(config.out)

  if config.command == "scan" then
    run_scan(config)
  elseif config.command == "classify" then
    run_classify(config)
  elseif config.command == "run" then
    run_classify(config)
  else
    error("unsupported command for first cut: " .. config.command)
  end
end

return M
